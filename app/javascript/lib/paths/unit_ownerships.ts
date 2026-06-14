export function adminResidentialPropertyUnitOwnershipsPath(
  residentialPropertyId: string,
  unitId: string,
): string {
  return `/admin/residential_properties/${residentialPropertyId}/units/${unitId}/ownerships`
}

export function adminResidentialPropertyUnitOwnershipPath(
  residentialPropertyId: string,
  unitId: string,
  ownershipId: string,
): string {
  return `${adminResidentialPropertyUnitOwnershipsPath(residentialPropertyId, unitId)}/${ownershipId}`
}
