# Azure Policy for Kubernetes (the add-on syncs in ~15 min).
# Built-in definition "Kubernetes cluster should not allow privileged containers".
# Verify the ID in Portal > Policy > Definitions if apply complains.
resource "azurerm_resource_group_policy_assignment" "no_privileged" {
  name                 = "deny-privileged-containers"
  resource_group_id    = azurerm_resource_group.rg.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/95edb821-ddaf-4404-9732-666045e056b4"
  parameters = jsonencode({
    effect = { value = "Deny" }
  })
}
