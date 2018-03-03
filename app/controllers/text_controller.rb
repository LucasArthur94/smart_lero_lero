class TextController < ApplicationController
  def new

  end

  def show
    current_page = 1
    char_quantity = 150
    language = :pt

    relevant_paragraphs = find_relevant_paragraphs(words, paragraphs, 0, current_page, char_quantity, language)

    @text = relevant_paragraphs.each_with_index.map do |reference, index|
      if index == 0
        reference.first
      elsif index == relevant_paragraphs.length - 1
        reference.last
      else
        reference.sample
      end
    end

    render :show, text: @text
  end

  private

  def find_relevant_paragraphs(words, paragraphs, previous_results, current_page, char_quantity, language)
    query = words.join("+")
    url_search = "https://www.google.com.br/search?q=#{query}+filetype%3Ahtml&start=#{(current_page * 10) - 10}"

    search = Nokogiri::HTML(open(url_search))

    results = search.xpath('//h3/a').map do |node|
      pre_url = node['href']
      pre_url.slice! "/url?q="
      pre_url.split('&sa')[0]
    end

    selected_paragraphs = results.map do |result|
      begin
        Nokogiri::HTML(open(result)).css('p').map do |p_tag|
          paragraph = p_tag.content.strip
          if paragraph.language_iso == language && paragraph.length > char_quantity
            relevant = words.map do |word|
              paragraph.downcase.include? " #{word} "
            end
            paragraph if relevant.any?
          end
        end.compact.reject { |c| c.empty? }
      rescue Errno::ENOENT
        # p "Errno::ENOENT"
      rescue OpenURI::HTTPError
        # p "OpenURI::HTTPError"
      rescue URI::InvalidURIError
        # p "URI::InvalidURIError"
      rescue RuntimeError
        # p "RuntimeError"
      rescue OpenSSL::SSL::SSLError
        # p "OpenSSL::SSL::SSLError"
      end
    end.compact.reject { |c| c.empty? }

    if previous_results + selected_paragraphs.length < paragraphs
      selected_paragraphs + find_relevant_paragraphs(words, paragraphs, selected_paragraphs.length + previous_results, current_page + 1, char_quantity, language) 
    else
      selected_paragraphs
    end
  end

  def text_params
    params.fetch(:text, {:words, :char_quantity})
  end

end
