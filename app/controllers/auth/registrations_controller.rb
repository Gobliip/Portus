class Auth::RegistrationsController < Devise::RegistrationsController
  layout 'authentication', except: :edit

  before_action :check_admin, only: [:new, :create]
  before_action :configure_sign_up_params, only: [:create]

  # Re-implemented so the template has the auxiliary variables regarding if
  # there are more users on the system or this is the first user to be created.
  def new
    @have_users = User.any?
    super
  end

  def create
    build_resource(sign_up_params)

    resource.save
    if resource.persisted?
      set_flash_message :notice, :signed_up
      sign_up(resource_name, resource)
      respond_with resource, location: after_sign_up_path_for(resource)
    else
      redirect_to new_user_registration_url,
        alert: resource.errors.full_messages
    end
  end

  def update
    success =
    if password_update?
      succ = current_user.update_with_password(params.require(:user).permit(
        :password, :password_confirmation, :current_password
      ))
      sign_in(current_user, bypass: true) if succ
      succ
    else
      current_user.update_without_password(params.require(:user).permit(:email))
    end

    if success
      redirect_to edit_user_registration_url,
        notice: 'Profile updated successfully!'
    else
      redirect_to edit_user_registration_url,
        alert: resource.errors.full_messages
    end
  end

  # Devise does not allow to disable routes on purpose. Ideally, though we
  # could still be able to disable the `destroy` method through the
  # `routes.rb` file as described in the wiki (by disabling all the routes and
  # calling `devise_scope` manually). However, this solution has the caveat
  # that it would ignore some calls (e.g. the `layout` call above). Therefore,
  # the best solution is to just implement a `destroy` method that just returns
  # a 404.
  def destroy
    render nothing: true, status: 404
  end

  def check_admin
    @admin = User.exists?(admin: true)
  end

  def configure_sign_up_params
    devise_parameter_sanitizer.for(:sign_up) << :email
    return if User.exists?(admin: true)
    devise_parameter_sanitizer.for(:sign_up) << :admin
  end

  protected

  # Returns true if the contents of the `params` hash contains the needed keys
  # to update the password of the user.
  def password_update?
    user = params[:user]
    !user[:current_password].blank? || !user[:password].blank? ||
      !user[:password_confirmation].blank?
  end
end
