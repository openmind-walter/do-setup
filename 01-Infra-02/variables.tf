# Registry Subscription Tier
variable "subscription_tier" {
  description = "The subscription tier slug (starter, basic, or professional)."
  type        = string
  default     = "starter" 
  validation {
    condition = contains(["starter", "basic", "professional"], lower(var.subscription_tier))
    error_message = "The subscription_tier must be 'starter', 'basic', or 'professional'."
  }
}
