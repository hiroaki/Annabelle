Rails.application.config.session_store(:active_record_store,
  key: '_Annabelle_session',
  same_site: :lax,
  expire_after: 14.days,
  secure: Rails.env.production?,
)
