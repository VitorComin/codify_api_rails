class DocumentsController < ApplicationController
  require 'base64'

  def index
    @documents = Document.all
  end

  def show
    @document = Document.find(params[:id])

    if @document.active
      if @document.created_at < 24.hours.ago
        decoded_password = Base64.decode64(@document.security_password)
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
    if params[:file].present?
      upload_result = Cloudinary::Uploader.upload(params[:file])
      if upload_result["secure_url"].present?
        encoded_password = Base64.encode64(params[:document][:security_password])
        @document = Document.new({ url: upload_result["secure_url"], active: true }.merge(document_params))
        @document.security_password = encoded_password

        if @document.save
          render json: @document, status: :created
        else
          render json: @document.errors, status: :unprocessable_entity
        end
      else
        render json: { error: "Erro ao fazer upload do arquivo." }, status: :unprocessable_entity
      end
    else
      render json: { error: "Nenhum arquivo enviado." }, status: :unprocessable_entity
    end
  end

  private

  def document_params
    params.require(:document).permit(:message, :security_password)
  end
end
