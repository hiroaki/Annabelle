[Japanese version is here](LOCALE_SYSTEM_DESCRIPTION.ja.md)

# Annabelle Locale System Design and Implementation Guide

## 1. Overview

Annabelle's locale system is based on routing with explicit URL prefixes such as `/ja/` and `/en/`, and it determines or switches to the most appropriate locale for each user and request.
This design provides consistent multilingual behavior throughout the application while keeping the system flexible and maintainable.

---

## 2. Locale Design Principles and Runtime Behavior

- **Principle of locale-prefixed URLs**
  Major screens and APIs are provided under locale-scoped URLs such as `/ja/...` and `/en/...`.
  This makes the current language state explicit in the URL itself, which is strong for SEO, bookmarks, and external integrations.

  ```
  # Examples of locale-prefixed URLs
  /ja                           # Japanese top page (messages#index)
  /en                           # English top page (messages#index)
  /ja/messages                  # Japanese message index
  /en/messages                  # English message index
  /ja/dashboard                 # Japanese dashboard
  /en/dashboard                 # English dashboard
  /ja/profile/edit              # Japanese profile edit
  /en/profile/edit              # English profile edit
  ```

- **Exception paths outside locale management**
  Some paths operate outside the locale scope, such as OAuth callbacks and certain external service endpoints.
  These paths are outside the scope of Annabelle's locale management, including automatic locale detection, redirects, and locale-aware 404 handling, and are handled individually through normal Rails routing and controllers.

  ```
  # Examples of exception paths
  /users/auth/github/callback   # GitHub OAuth callback
  /users/auth/failure           # OAuth authentication failure
  /up                           # Health check
  ```

- **Automatic locale detection and redirect on root access**
  When `/` is accessed, `LocaleUtils` determines the locale in the following order: parameter, user preference, `Accept-Language` header, and default locale. It then redirects to the top page for the resolved locale such as `/ja` or `/en`.

  ```
  # Redirect examples
  GET /                           -> redirect -> GET /ja
  GET /?locale=en                 -> redirect -> GET /en
  GET / (Accept-Language: en-US)  -> redirect -> GET /en
  ```

- **Locale switching through a dedicated endpoint**
  Accessing `/locale/:locale` redirects to the path specified by the `redirect_to` parameter when the given locale is valid, or to the locale top page otherwise.

  ```
  # Locale switch examples
  GET /locale/ja                                   -> redirect -> GET /ja
  GET /locale/en?redirect_to=/en/dashboard         -> redirect -> GET /en/dashboard
  GET /locale/ja?redirect_to=/ja/messages          -> redirect -> GET /ja/messages
  GET /locale/invalid                              -> redirect -> GET / with alert
  ```

- **Language switching within the locale scope**
  Within the locale scope, the language switch UI and URL helper utilities allow navigation to the same path in another language.

  ```
  Current page: /en/dashboard
  -> Click Japanese language switch link
  Destination: /ja/dashboard
  ```

- **Common error handling**
  When an unsupported locale is specified, the application redirects to the root path and displays an alert when appropriate. This behavior is shared across the system.

  ```
  # Error handling examples
  GET /fr/messages                -> 404 Not Found
  GET /locale/fr                  -> redirect -> GET / with alert
  ```

---

## 3. Main Components and Responsibilities

- **LocaleController**
  Handles automatic redirects on root access, explicit locale switching through `/locale/:locale`, and error handling for invalid locales.

- **LocaleUtils**
  Provides locale resolution logic. The priority order is parameter, user preference, `Accept-Language` header, and default locale.

- **LocaleValidator**
  Centralizes validation of whether a locale is supported.

- **LocaleHelper**
  Provides path-based locale extraction, insertion, removal, OAuth-related parameter generation, and other URL utility behavior.

- **LocaleConfiguration**
  Loads available locales, the default locale, and metadata from `config/locales.yml`, and provides them through an API.

---

## 4. Structure and Role of `config/locales.yml`

Annabelle manages locale settings centrally in `config/locales.yml`.

```yaml
locales:
  default: en
  available:
    - en
    - ja
  metadata:
    en:
      name: "English"
      native_name: "English"
      direction: ltr
    ja:
      name: "Japanese"
      native_name: "Japanese"
      direction: ltr
```

- **default**
  The default locale. It is used on root access and when locale resolution fails.

- **available**
  The list of available locales. Only locales listed here are valid.

- **metadata**
  Locale metadata such as display name (`name`), native name (`native_name`), and text direction (`direction`).
  These values are used in UI rendering and language switch UI generation.
  `direction` indicates text flow direction, where `ltr` means left-to-right and `rtl` means right-to-left.