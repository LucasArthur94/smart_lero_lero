class TextsController < ApplicationController
  before_action :set_text, only: [:show, :edit, :update, :destroy]

  # GET /texts
  # GET /texts.json
  def index
    @texts = Text.all
  end

  # GET /texts/1
  # GET /texts/1.json
  def show
  end

  # GET /texts/new
  def new
    @text = Text.new
  end

  # GET /texts/1/edit
  def edit
  end

  # POST /texts
  # POST /texts.json
  def create
    @text = Text.new(text_params)

    @text.generated_text = generate_text(@text.words, @text.paragraphs, @text.char_quantity, @text.language_iso.to_sym).join("\n")

    respond_to do |format|
      if @text.save
        format.html { redirect_to @text, notice: 'Text was successfully created.' }
        format.json { render :show, status: :created, location: @text }
      else
        format.html { render :new }
        format.json { render json: @text.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /texts/1
  # PATCH/PUT /texts/1.json
  def update
    respond_to do |format|
      if @text.update(text_params)
        format.html { redirect_to @text, notice: 'Text was successfully updated.' }
        format.json { render :show, status: :ok, location: @text }
      else
        format.html { render :edit }
        format.json { render json: @text.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /texts/1
  # DELETE /texts/1.json
  def destroy
    @text.destroy
    respond_to do |format|
      format.html { redirect_to texts_url, notice: 'Text was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_text
      @text = Text.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def text_params
      params.require(:text).permit(:words, :paragraphs, :language_iso, :char_quantity, :generated_text)
    end

    def generate_text(words, paragraphs, char_quantity, language_iso)
      relevant_paragraphs = find_relevant_paragraphs(words, paragraphs, 0, 1, char_quantity, language_iso)

      relevant_paragraphs.each_with_index.map do |reference, index|
        if index == 0
          reference.first
        elsif index == relevant_paragraphs.length - 1
          reference.last
        else
          reference.sample
        end
      end
    end


    def find_relevant_paragraphs(words, paragraphs, previous_results, current_page, char_quantity, language_iso)
      query = words.split.join("+")

      hash = { q: query, filetype: "html", start: ((current_page * 10) - 10) }

      query_string = hash.to_query

      url_search = "https://www.google.com.br/search?#{query_string}"

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
            if paragraph.language_iso == language_iso && paragraph.length > char_quantity
              relevant = words.split.map do |word|
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
        selected_paragraphs + find_relevant_paragraphs(words, paragraphs, selected_paragraphs.length + previous_results, current_page + 1, char_quantity, language_iso) 
      else
        selected_paragraphs
      end
    end
end
