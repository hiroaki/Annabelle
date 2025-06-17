module DeviseHelper
  def devise_path_for(action, resource)
    mapping = Devise.mappings[resource.class.name.underscore.to_sym]
    helper_name = "#{action}_#{mapping.singular}_registration_path"

    if respond_to?(helper_name)
      send(helper_name)
    else
      nil
    end
  end
end
