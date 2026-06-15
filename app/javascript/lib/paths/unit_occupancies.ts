export function adminResidentialPropertyUnitOccupanciesPath(
  residentialPropertyId: string,
  unitId: string,
): string {
  return `/admin/residential_properties/${residentialPropertyId}/units/${unitId}/occupancies`
}

export function adminResidentialPropertyUnitOccupancyPath(
  residentialPropertyId: string,
  unitId: string,
  occupancyId: string,
): string {
  return `${adminResidentialPropertyUnitOccupanciesPath(residentialPropertyId, unitId)}/${occupancyId}`
}

export function adminResidentialPropertyUnitOccupanciesActiveElsewherePath(
  residentialPropertyId: string,
  unitId: string,
  personId: string,
): string {
  const params = new URLSearchParams({ person_id: personId })
  return `${adminResidentialPropertyUnitOccupanciesPath(residentialPropertyId, unitId)}/active_elsewhere?${params.toString()}`
}
