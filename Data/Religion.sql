-- Религиозная присяга: карточки правительства, увеличивающие лимит агитаций Апостола
INSERT OR IGNORE INTO Types (Type, Kind) VALUES
('POLICY_RO_PREACHERS', 'KIND_POLICY'),
('POLICY_RO_MISSION_ORDER', 'KIND_POLICY');

INSERT OR IGNORE INTO Policies (PolicyType, Name, Description, PrereqCivic, GovernmentSlotType) VALUES
('POLICY_RO_PREACHERS', 'LOC_POLICY_RO_PREACHERS_NAME', 'LOC_POLICY_RO_PREACHERS_DESCRIPTION', 'CIVIC_THEOLOGY', 'SLOT_DIPLOMATIC'),
('POLICY_RO_MISSION_ORDER', 'LOC_POLICY_RO_MISSION_ORDER_NAME', 'LOC_POLICY_RO_MISSION_ORDER_DESCRIPTION', 'CIVIC_REFORMED_CHURCH', 'SLOT_DIPLOMATIC');

-- "Проповедники" устаревают, когда становится доступен "Миссионерский орден"
INSERT OR IGNORE INTO ObsoletePolicies (PolicyType, ObsoletePolicy) VALUES
('POLICY_RO_PREACHERS', 'POLICY_RO_MISSION_ORDER');
