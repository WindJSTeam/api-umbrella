local RateLimit = require "api-umbrella.lapis.models.rate_limit"
local cjson = require "cjson"
local model_ext = require "api-umbrella.utils.model_ext"
local t = require("resty.gettext").gettext
local validation_ext = require "api-umbrella.utils.validation_ext"

local json_null = cjson.null
local validate_field = model_ext.validate_field

local ApiUserSettings = model_ext.new_class("api_user_settings", {
  relations = {
    { "rate_limits", has_many = "RateLimit", key = "api_user_settings_id" },
  },

  as_json = function(self)
    local data = {
      id = self.id or json_null,
      allowed_ips = self.allowed_ips or json_null,
      allowed_referers = self.allowed_referers or json_null,
      rate_limit_mode = self.rate_limit_mode or json_null,
      rate_limits = {},
    }

    local rate_limits = self:get_rate_limits()
    for _, rate_limit in ipairs(rate_limits) do
      table.insert(data["rate_limits"], rate_limit:as_json())
    end
    setmetatable(data["rate_limits"], cjson.empty_array_mt)

    return data
  end,

  rate_limits_update_or_create = function(self, rate_limit_values)
    return model_ext.has_many_update_or_create(self, RateLimit, "api_user_settings_id", rate_limit_values)
  end,

  rate_limits_delete_except = function(self, keep_rate_limit_ids)
    return model_ext.has_many_delete_except(self, RateLimit, "api_user_settings_id", keep_rate_limit_ids)
  end,
}, {
  authorize = function()
    return true
  end,

  validate = function(_, data)
    local errors = {}
    validate_field(errors, data, "rate_limit_mode", validation_ext.db_null_optional:regex("^(unlimited|custom)$", "jo"), t("is not included in the list"))

    return errors
  end,

  after_save = function(self, values)
    model_ext.has_many_save(self, values, "rate_limits")
  end
})

return ApiUserSettings
