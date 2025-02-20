# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UploadsController do
  include WorkhorseHelpers

  let(:model) { create(:project, :public) }
  let(:params) do
    { namespace_id: model.namespace.to_param, project_id: model }
  end

  let(:other_model) { create(:project, :public) }
  let(:other_params) do
    { namespace_id: other_model.namespace.to_param, project_id: other_model }
  end

  it_behaves_like 'handle uploads'

  context 'when the URL the old style, without /-/system' do
    it 'responds with a redirect to the login page' do
      get :show, params: { namespace_id: 'project', project_id: 'avatar', filename: 'foo.png', secret: 'bar' }

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'with a moved project' do
    let!(:upload) { create(:upload, :issuable_upload, :with_file, model: model) }
    let(:project) { model }
    let(:upload_path) { File.basename(upload.path) }
    let!(:redirect_route) { project.redirect_routes.create!(path: project.full_path + 'old') }

    it 'redirects to a file with the proper extension' do
      get :show, params: { namespace_id: project.namespace, project_id: project.to_param + 'old', filename: File.basename(upload.path), secret: upload.secret }

      expect(response.location).to eq(show_project_uploads_url(project, upload.secret, upload_path))
      expect(response.location).to end_with(upload.path)
      expect(response).to have_gitlab_http_status(:redirect)
    end
  end

  context "when exception occurs" do
    before do
      allow(FileUploader).to receive(:workhorse_authorize).and_raise(SocketError.new)
      sign_in(create(:user))
    end

    it "responds with status internal_server_error" do
      post_authorize

      expect(response).to have_gitlab_http_status(:internal_server_error)
      expect(response.body).to eq(_('Error uploading file'))
    end
  end

  describe "GET #show" do
    let(:filename) { "rails_sample.jpg" }
    let(:user)  { create(:user) }
    let(:jpg)   { fixture_file_upload('spec/fixtures/rails_sample.jpg', 'image/jpg') }
    let(:txt)   { fixture_file_upload('spec/fixtures/doc_sample.txt', 'text/plain') }
    let(:secret) { FileUploader.generate_secret }
    let(:uploader_class) { FileUploader }

    let(:upload_service) do
      UploadService.new(model, jpg, uploader_class).execute
    end

    let(:show_upload) do
      get :show, params: params.merge(secret: secret, filename: filename)
    end

    before do
      allow(FileUploader).to receive(:generate_secret).and_return(secret)

      allow_next_instance_of(FileUploader) do |instance|
        allow(instance).to receive(:image?).and_return(true)
      end

      upload_service
    end

    context 'when project is private do' do
      before do
        model.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
      end

      context "when not signed in" do
        context "enforce_auth_checks_on_uploads feature flag" do
          context "with flag enabled" do
            before do
              stub_feature_flags(enforce_auth_checks_on_uploads: true)
            end

            context 'when the project has setting enforce_auth_checks_on_uploads true' do
              before do
                model.update!(enforce_auth_checks_on_uploads: true)
              end

              it "responds with status 302" do
                show_upload

                expect(response).to have_gitlab_http_status(:redirect)
              end
            end

            context 'when the project has setting enforce_auth_checks_on_uploads false' do
              before do
                model.update!(enforce_auth_checks_on_uploads: false)
              end

              it "responds with status 200" do
                show_upload

                expect(response).to have_gitlab_http_status(:ok)
              end
            end
          end

          context "with flag disabled" do
            before do
              stub_feature_flags(enforce_auth_checks_on_uploads: false)
            end

            it "responds with status 200" do
              show_upload

              expect(response).to have_gitlab_http_status(:ok)
            end
          end
        end
      end

      context "when signed in" do
        before do
          sign_in(user)
        end

        context "when the user doesn't have access to the model" do
          context "enforce_auth_checks_on_uploads feature flag" do
            context "with flag enabled" do
              before do
                stub_feature_flags(enforce_auth_checks_on_uploads: true)
              end

              context 'when the project has setting enforce_auth_checks_on_uploads true' do
                before do
                  model.update!(enforce_auth_checks_on_uploads: true)
                end

                it "responds with status 404" do
                  show_upload

                  expect(response).to have_gitlab_http_status(:not_found)
                end
              end

              context 'when the project has setting enforce_auth_checks_on_uploads false' do
                before do
                  model.update!(enforce_auth_checks_on_uploads: false)
                end

                it "responds with status 200" do
                  show_upload

                  expect(response).to have_gitlab_http_status(:ok)
                end
              end
            end
          end

          context "with flag disabled" do
            before do
              stub_feature_flags(enforce_auth_checks_on_uploads: false)
            end

            it "responds with status 200" do
              show_upload

              expect(response).to have_gitlab_http_status(:ok)
            end
          end
        end
      end
    end

    context 'when project is public' do
      before do
        model.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
      end

      context "when not signed in" do
        context "enforce_auth_checks_on_uploads feature flag" do
          context "with flag enabled" do
            before do
              stub_feature_flags(enforce_auth_checks_on_uploads: true)
            end

            context 'when the project has setting enforce_auth_checks_on_uploads true' do
              before do
                model.update!(enforce_auth_checks_on_uploads: true)
              end

              it "responds with status 200" do
                show_upload

                expect(response).to have_gitlab_http_status(:ok)
              end
            end

            context 'when the project has setting enforce_auth_checks_on_uploads false' do
              before do
                model.update!(enforce_auth_checks_on_uploads: false)
              end

              it "responds with status 200" do
                show_upload

                expect(response).to have_gitlab_http_status(:ok)
              end
            end
          end

          context "with flag disabled" do
            before do
              stub_feature_flags(enforce_auth_checks_on_uploads: false)
            end

            it "responds with status 200" do
              show_upload

              expect(response).to have_gitlab_http_status(:ok)
            end
          end
        end
      end

      context "when signed in" do
        before do
          sign_in(user)
        end

        context "when the user doesn't have access to the model" do
          context "enforce_auth_checks_on_uploads feature flag" do
            context "with flag enabled" do
              before do
                stub_feature_flags(enforce_auth_checks_on_uploads: true)
              end

              context 'when the project has setting enforce_auth_checks_on_uploads true' do
                before do
                  model.update!(enforce_auth_checks_on_uploads: true)
                end

                it "responds with status 200" do
                  show_upload

                  expect(response).to have_gitlab_http_status(:ok)
                end
              end

              context 'when the project has setting enforce_auth_checks_on_uploads false' do
                before do
                  model.update!(enforce_auth_checks_on_uploads: false)
                end

                it "responds with status 200" do
                  show_upload

                  expect(response).to have_gitlab_http_status(:ok)
                end
              end
            end
          end

          context "with flag disabled" do
            before do
              stub_feature_flags(enforce_auth_checks_on_uploads: false)
            end

            it "responds with status 200" do
              show_upload

              expect(response).to have_gitlab_http_status(:ok)
            end
          end
        end
      end
    end
  end

  def post_authorize(verified: true)
    request.headers.merge!(workhorse_internal_api_request_header) if verified

    post :authorize, params: { namespace_id: model.namespace, project_id: model.path }, format: :json
  end
end
