locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Scaffold only. Add network, database, and app modules next (ADR-002).
