variable "location" {
  description = "The location of the resources (must be a region allowed by your subscription policy)"
  type        = string
  default     = "francecentral"
}

variable "prefix" {
  description = "The prefix of the resources"
  type        = string
  default     = "tp-terraform"
}

variable "id_sub_azure" {
  description = "The ID of the Azure subscription"
  type        = string

}