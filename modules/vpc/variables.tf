# --- Naming Convention Variables ---

variable "project_code" {
  description = "3-character project code (e.g., cis)"
  type        = string
}

variable "environment" {
  description = "Environment tier (e.g., prd, uat)"
  type        = string
}

variable "network_zone" {
  description = "2-character network zone (e.g., ia for intranet)"
  type        = string
}

# --- Core Network Variables ---

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "transit_gateway_id" {
  description = "ID of the Transit Gateway. If provided, attaches the VPC to the TGW."
  type        = string
  default     = null
}

# --- CSV-Driven Data Variables ---

variable "subnets" {
  description = "Map of subnet configurations parsed from subnets.csv"
  type = map(object({
    cidr_block = string
    az         = string
    is_public  = bool
    role       = string # e.g., web, app, eks, db
  }))
}

variable "sg_rules" {
  description = "List of maps containing Security Group rules parsed from sg_rules.csv"
  type        = list(map(string))
  default     = []
}

variable "nacl_rules" {
  description = "List of maps containing NACL rules parsed from nacl_rules.csv"
  type        = list(map(string))
  default     = []
}

variable "route_rules" {
  description = "List of maps containing Route rules parsed from route_rules.csv"
  type        = list(map(string))
  default     = []
}

variable "common_tags" {
  description = "Common tags to apply to all VPC resources"
  type        = map(string)
  default     = {}
}