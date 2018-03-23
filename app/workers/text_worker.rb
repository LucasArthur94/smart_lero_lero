class TextWorker
  include Sidekiq::Worker

  def perform(text_id)
    @text = Text.find(text_id)
    @text.generated_text = generate_text(@text.words, @text.paragraphs, @text.char_quantity, @text.language_iso.to_sym)
    @text.save
  end

  private

  def generate_text(words, paragraphs, char_quantity, language_iso)
    relevant_paragraphs = find_relevant_paragraphs(words, paragraphs, 0, 1, char_quantity, language_iso)

    if relevant_paragraphs.present?
      @text.update(status: "done")
      relevant_paragraphs.each_with_index.map do |reference, index|
        if index == 0
          reference.first
        elsif index == relevant_paragraphs.length - 1
          reference.last
        else
          reference.sample
        end
      end.join("\n")
    else
      ""
    end
  end


  def find_relevant_paragraphs(words, paragraphs, previous_results, current_page, char_quantity, language_iso)
    query = words.split.join("+")

    hash = {
      key: "AIzaSyCRNOK2iX-fVrhZYRgL-q-g9DeQn4wlKaI",
      cx: "006486813528355849225:y_ixysq2dsm",
      q: query,
      filetype: "html",
      start: ((current_page * 10) - 9)
    }

    query_string = hash.to_query

    url_search = "https://www.googleapis.com/customsearch/v1?#{query_string}"

    search = JSON.parse(HTTParty.get(url_search, format: :plain), symbolize_names: true)

    begin
      results = search[:items].map do |item|
        item[:link]
      end
    rescue NoMethodError
      @text.update(status: "error")
      []
    end

    selected_paragraphs = results.map do |result|
      begin
        Nokogiri::HTML(open(result)).css('p').map do |p_tag|
          paragraph = p_tag.content.strip
          if paragraph.language_iso == language_iso && paragraph.length > char_quantity
            relevant = words.split.map do |word|
              paragraph.downcase.include? " #{word} "
            end
            paragraph if relevant.any?
          end
        end.compact.reject { |c| c.empty? }
      rescue Errno::ENOENT
        # p "Errno::ENOENT"
      rescue Errno::ECONNREFUSED
        # p "Errno::ECONNREFUSED"
      rescue OpenURI::HTTPError
        # p "OpenURI::HTTPError"
      rescue URI::InvalidURIError
        # p "URI::InvalidURIError"
      rescue RuntimeError
        # p "RuntimeError"
      rescue OpenSSL::SSL::SSLError
        # p "OpenSSL::SSL::SSLError"
      rescue SocketError
        # p "SocketError"
      end
    end.compact.reject { |c| c.empty? }

    if previous_results + selected_paragraphs.length < paragraphs
      selected_paragraphs + find_relevant_paragraphs(words, paragraphs, selected_paragraphs.length + previous_results, current_page + 1, char_quantity, language_iso) 
    else
      selected_paragraphs
    end
  end
end
