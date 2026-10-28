-- ===========================================================================
-- РЕЦЕПТЫ: дополнительные ресурсы для создания юнитов и зданий (смеси ресурсов).
-- Каждый ресурс рецепта отдельно пересчитывается по квоте:
--   C(r) = max(BaseCost, round(мировой запас r / 6))
-- Основной ресурс юнита (Units_XP2) и здания (Building_ResourceCosts) по-прежнему
-- задаётся в Units.sql / Buildings.sql; здесь — всё, что берётся ДОПОЛНИТЕЛЬНО.
-- Чтобы добавить ресурс в рецепт — допишите строку (UnitType/BuildingType, ResourceType, BaseCost).
-- ===========================================================================
CREATE TABLE IF NOT EXISTS RO_UnitExtraCosts (
    UnitType TEXT NOT NULL,
    ResourceType TEXT NOT NULL,
    BaseCost INTEGER NOT NULL,
    PRIMARY KEY (UnitType, ResourceType)
);

CREATE TABLE IF NOT EXISTS RO_BuildingExtraCosts (
    BuildingType TEXT NOT NULL,
    ResourceType TEXT NOT NULL,
    BaseCost INTEGER NOT NULL,
    PRIMARY KEY (BuildingType, ResourceType)
);

-- Гражданские юниты
INSERT OR REPLACE INTO RO_UnitExtraCosts (UnitType, ResourceType, BaseCost) VALUES
-- Поселенец (с 3-го; 1-й и 2-й бесплатно): еда + товары роскоши + камень
('UNIT_SETTLER', 'RESOURCE_FOOD', 30),
('UNIT_SETTLER', 'RESOURCE_LUXURY_GOODS', 10),
('UNIT_SETTLER', 'RESOURCE_STONE', 10);

-- Военные юниты: обязательный паёк Провизии
INSERT OR REPLACE INTO RO_UnitExtraCosts (UnitType, ResourceType, BaseCost) VALUES
('UNIT_SLINGER', 'RESOURCE_FOOD', 10),
('UNIT_ARCHER', 'RESOURCE_FOOD', 10),
('UNIT_SPEARMAN', 'RESOURCE_FOOD', 10),
('UNIT_HEAVY_CHARIOT', 'RESOURCE_FOOD', 10),
('UNIT_HORSEMAN', 'RESOURCE_FOOD', 10),
('UNIT_SWORDSMAN', 'RESOURCE_FOOD', 10),
('UNIT_CATAPULT', 'RESOURCE_FOOD', 10),
('UNIT_GALLEY', 'RESOURCE_FOOD', 10),
('UNIT_QUADRIREME', 'RESOURCE_FOOD', 10),
('UNIT_CROSSBOWMAN', 'RESOURCE_FOOD', 15),
('UNIT_PIKEMAN', 'RESOURCE_FOOD', 15),
('UNIT_MAN_AT_ARMS', 'RESOURCE_FOOD', 15),
('UNIT_KNIGHT', 'RESOURCE_FOOD', 15),
('UNIT_COURSER', 'RESOURCE_FOOD', 15),
('UNIT_TREBUCHET', 'RESOURCE_FOOD', 15),
('UNIT_PIKE_AND_SHOT', 'RESOURCE_FOOD', 15),
('UNIT_MUSKETMAN', 'RESOURCE_FOOD', 15),
('UNIT_CUIRASSIER', 'RESOURCE_FOOD', 15),
('UNIT_BOMBARD', 'RESOURCE_FOOD', 15),
('UNIT_CARAVEL', 'RESOURCE_FOOD', 15),
('UNIT_FRIGATE', 'RESOURCE_FOOD', 15),
('UNIT_LINE_INFANTRY', 'RESOURCE_FOOD', 20),
('UNIT_FIELD_CANNON', 'RESOURCE_FOOD', 20),
('UNIT_CAVALRY', 'RESOURCE_FOOD', 20),
('UNIT_IRONCLAD', 'RESOURCE_FOOD', 20),
('UNIT_INFANTRY', 'RESOURCE_FOOD', 20),
('UNIT_MACHINE_GUN', 'RESOURCE_FOOD', 20),
('UNIT_AT_CREW', 'RESOURCE_FOOD', 20),
('UNIT_ARTILLERY', 'RESOURCE_FOOD', 20),
('UNIT_TANK', 'RESOURCE_FOOD', 20),
('UNIT_BATTLESHIP', 'RESOURCE_FOOD', 20),
('UNIT_SUBMARINE', 'RESOURCE_FOOD', 20),
('UNIT_MODERN_AT', 'RESOURCE_FOOD', 20),
('UNIT_FIGHTER', 'RESOURCE_FOOD', 20),
('UNIT_BOMBER', 'RESOURCE_FOOD', 20),
('UNIT_JET_FIGHTER', 'RESOURCE_FOOD', 20),
('UNIT_JET_BOMBER', 'RESOURCE_FOOD', 20),
('UNIT_MODERN_ARMOR', 'RESOURCE_FOOD', 20),
('UNIT_NUCLEAR_SUBMARINE', 'RESOURCE_FOOD', 20),
('UNIT_MISSILE_CRUISER', 'RESOURCE_FOOD', 20);
