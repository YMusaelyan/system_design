workspace "Warehouse Management System" "Система управления складом" {

    !identifiers hierarchical

    model {
        manager = person "Warehouse manager" "Контролирует и управляет приемкой и спианием товаров на складе "
        
        warehouse = softwareSystem "Warehouse Management System" {

            warehousedb = container "Database" "Хранит данные пользователей, товаров, перемещений товаров на складе" "PostgreSQL" "database"
            redis = container "Cache" "Кэширование остатков товаров" "Redis" "redis"

            web = container "Web Browser" "Веб-интерфейс системы управлением склада" "Web Browser"
            gateway = container "API Gateway" "Маршрутизация запросов" "Userver"

            managerService = container "User Service" "Сервис управления менеджерами" "Userver"
            productService = container "Product Service" "Каталог товаров и остатки" "Userver"
            inventoryService = container "Inventory Service" "Учёт перемещения товара(приема и списания товара)" "Userver"

            manager -> managerService "Инициирует запрос на создание поступления или списания"

            managerService -> warehousedb "Создание/поиск по логину, маске имя и фамилия пользователя"
            managerService -> web "Управление товарами/Взаимодействие с веб"

            productService -> warehousedb "Добавление/поиск по названию товара"
            productService -> redis "Кэш остатков"

            inventoryService -> warehousedb "Получение истории о поступлении/списании"
            inventoryService -> productService "Обновление товаров при поступлении/списании"

            web -> gateway "Вызовы API от веб" "HTTPS"

            gateway -> managerService "Маршрутизация запросов по пользотелям" "HTTPS"
            gateway -> productService "Маршрутизация запросов по товарам" "HTTPS"
            gateway -> inventoryService "Маршрутизация запросов по передвижению товаров(списание/поступление)" "HTTPS"
        }
    
    }
    views {
        systemContext warehouse "SystemContext" {
            include *
            autolayout
        }

        container warehouse "Containers" {
            include *
            autolayout lr
        }

        dynamic warehouse "InventoryTransferReceipt" "Создание поступления товара" {
            
            manager -> warehouse.managerService "Инициирует запрос на создание поступления товара"
            warehouse.managerService -> warehouse.web "Создаёт поступление товара"
            warehouse.web -> warehouse.gateway "POST /inventory/receipt {productId, quantity}"
            warehouse.gateway -> warehouse.inventoryService "Перенаправляет запрос"
            
            warehouse.inventoryService -> warehouse.productService "Запрашивает информацию о товаре"
            warehouse.productService -> warehouse.warehousedb "Поиск товара по ID"
            
            warehouse.inventoryService -> warehouse.warehousedb "Запись информации о поступлении"
            warehouse.inventoryService -> warehouse.productService "Обновление остатка товара"
            warehouse.productService -> warehouse.redis "Обновление кэша остатков товаров"
            
            warehouse.inventoryService -> warehouse.gateway "Возвращает подтверждение создания (201 Created)"
            warehouse.gateway -> warehouse.web "Отображает подтверждение о поступлении на склад"
            
            autolayout lr
        }

        styles {
            
            element "Person" {
                background #FFD700
                shape person
            }

            element "database" {
                shape Cylinder
                background #ADD8E6
                color #000000
            }

            element "redis" {
                shape Cylinder
                background #FFA500
                color #000000
            }

            element "Web Browser" {
                shape WebBrowser
            }

            element "softwareSystem" {
                strokeWidth 3 
                background #1E90FF
                color #ffffff
            }
        }
    }
}
