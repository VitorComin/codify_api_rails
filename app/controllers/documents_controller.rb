class DocumentsController < ApplicationController
    require 'base64'
    
    def index
      @documents = Document.all
    end
  
    def show
        @document = Document.find(params[:id])

        # Verifica se o documento está ativo
        if @document.active
            # Verifica se a data de criação do documento é anterior a 24 horas atrás
            if @document.created_at < 24.hours.ago
            # Decodifica a senha salva no banco de dados
            decoded_password = Base64.decode64(@document.security_password)
            
                # Verifica se a senha recebida é a mesma que a senha salva no banco de dados
                if params[:password] == decoded_password
                    render json: @document
                else
                    render json: { error: 'Senha incorreta.' }, status: :unauthorized
                end
            else
            render json: { error: 'Documento criado há mais de 24 horas.' }, status: :unprocessable_entity
            end
        else
            render json: { error: 'Documento inativo.' }, status: :unprocessable_entity
        end
    end
  
    def new
      @document = Document.new
    end
  
    def create
        # Verifica se um arquivo foi enviado
        if params[:file].present?
          # Envia o arquivo para o Cloudinary
          upload_result = Cloudinary::Uploader.upload(params[:file])
          
          # Verifica se o upload foi bem-sucedido e obtém a URL do arquivo no Cloudinary
          if upload_result["secure_url"].present?
            # Codifica a senha usando Base64
            encoded_password = Base64.encode64(params[:document][:security_password])
            
            # Cria um novo documento com a URL do arquivo e a senha codificada
            @document = Document.new(url: upload_result["secure_url"], document_params)
            @document.security_password = encoded_password
            
            # Salva o documento no banco de dados
            if @document.save
              redirect_to @document, notice: 'Document was successfully created.'
            else
              render :new
            end
          else
            # Lida com erros de upload
            flash[:error] = "Erro ao fazer upload do arquivo."
            render :new
          end
        else
          # Lida com a situação em que nenhum arquivo foi enviado
          flash[:error] = "Nenhum arquivo enviado."
          render :new
        end
      end
  
    private
  
    def document_params
        params.require(:document).permit(:message, :active)
    end
  end
  