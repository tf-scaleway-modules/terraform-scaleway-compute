## MODIFIED Requirements

### Requirement: Volume outputs
The module SHALL output `volumes` as a map of volume key `<server key>-vol-<NN>` to `{ id, name, type, srn }` for every additional volume the module creates, with `type` equal to `local` or `sbs`.

#### Scenario: Mixed volumes
- **WHEN** a server has one `l_ssd` and one `sbs_5k` volume
- **THEN** `volumes` has one entry of type `local` and one of type `sbs`, each with an `srn`
