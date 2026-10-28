UPDATE Resources
SET ResourceClassType = 'RESOURCECLASS_STRATEGIC'
WHERE ResourceClassType IN ('RESOURCECLASS_BONUS', 'RESOURCECLASS_LUXURY');

INSERT OR IGNORE INTO Types (Type, Kind) VALUES 
('RESOURCE_FOOD', 'KIND_RESOURCE'),
('RESOURCE_LUXURY_GOODS', 'KIND_RESOURCE');

INSERT OR IGNORE INTO Resources (ResourceType, Name, ResourceClassType, Frequency) VALUES 
('RESOURCE_FOOD', 'LOC_RESOURCE_FOOD_NAME', 'RESOURCECLASS_STRATEGIC', 0),
('RESOURCE_LUXURY_GOODS', 'LOC_RESOURCE_LUXURY_GOODS_NAME', 'RESOURCECLASS_STRATEGIC', 0);

INSERT OR REPLACE INTO Resource_Consumption (
    ResourceType,
    Accumulate,
    BaseExtractionRate,
    ImprovedExtractionRate,
    StockpileCap
)
SELECT 
    ResourceType,
    1,
    0,
    6,      -- добыча с улучшенной клетки в ход (было 2, x3)
    600     -- размер склада (было 200, x3)
FROM Resources
WHERE ResourceClassType = 'RESOURCECLASS_STRATEGIC';

UPDATE Resource_Consumption
SET StockpileCap = 600
WHERE StockpileCap < 600;

UPDATE Buildings
SET Entertainment = Entertainment + 4
WHERE BuildingType = 'BUILDING_PALACE';

UPDATE Buildings
SET Entertainment = Entertainment + 1
WHERE BuildingType = 'BUILDING_MONUMENT';

-- Пшеница, рис, бананы, рыба, крабы, скот больше не накапливаются сами (раньше давали 2 еды в ход):
-- теперь Lua начисляет за них Провизию (RESOURCE_FOOD_RATES в FoodConsolidation.lua).
UPDATE Resource_Consumption
SET ImprovedExtractionRate = 0
WHERE ResourceType IN ('RESOURCE_WHEAT', 'RESOURCE_RICE', 'RESOURCE_BANANAS', 'RESOURCE_FISH', 'RESOURCE_CRABS', 'RESOURCE_CATTLE');
