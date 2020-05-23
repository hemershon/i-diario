class RolesController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @roles = apply_scopes(Role.includes(:author).ordered)

    authorize @roles
  end

  def new
    @role = Role.new
    @role.author = current_user

    authorize @role

    paginate_permissions

    @role.build_permissions!
  end

  def create
    @role = Role.new(role_params)
    @role.author = current_user

    authorize @role

    if @role.save
      respond_with @role, location: roles_path
    else
      render :new
    end
  end

  def edit
    @role = Role.where(id: params[:id]).includes(
      :permissions,
      user_roles: [:user, :unity]
    ).first

    authorize @role

    paginate_user_roles

    @role.build_permissions!

    paginate_permissions
  end

  def update
    @role = Role.find(params[:id])

    authorize @role

    paginate_user_roles
    paginate_permissions

    if @role.update(role_params)
      respond_with @role, location: roles_path
    else
      flash[:alert] = []
      flash[:alert] << @role.errors.full_messages.to_sentence

      redirect_to edit_role_path(@role)
    end
  end

  def destroy
    @role = Role.find(params[:id])

    authorize @role

    @role.destroy

    respond_with @role, location: roles_path
  end

  def history
    @role = Role.find params[:id]

    authorize @role

    respond_with @role
  end

  private

  def users
    @users ||= User.ordered
  end
  helper_method :users

  def unities
    @unities ||= Unity.ordered
  end
  helper_method :unities

  def role_params
    params.require(:role).permit(
      :name, :access_level, :permissions_attributes => [:id, :feature, :permission],
      :user_roles_attributes => [
        :id, :user_id, :unity_id, :_destroy
      ]
    )
  end

  def paginate_user_roles
    page = params[:users_page]&.to_i
    sequence = params[:sequence]&.to_i

    @sequence = [nil, 1].include?(page) ? -1 : (page * 10) - (sequence + 2)
    @active_users_tab = to_boolean(params[:active_users_tab]) || false

    @user_roles = @role.user_roles.page(page).per(10)
    @user_roles = @user_roles.user_name(params[:user_name]) if (@user_name = params[:user_name])
    @user_roles = @user_roles.unity_name(params[:unity_name]) if (@unity_name = params[:unity_name])
  end

  def paginate_permissions
    page = params[:permissions_page]&.to_i
    @active_permissions_tab = to_boolean(params[:active_permissions_tab]) || false
    @active_permissions_tab = true if params[:active_permissions_tab].blank? && params[:active_users_tab].blank?

    permissions = @role.permissions

    access_level_permission_ids = permissions.select { |permission|
      permission.access_level_has_feature?(@role.access_level)
    }.map(&:id).compact

    @permissions = permissions.where(id: access_level_permission_ids).page(page).per(10)
  end

  def to_boolean(param)
    ActiveRecord::Type::Boolean.new.type_cast_from_user(param)
  end
end
