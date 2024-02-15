## Домашнее задание 04
*Подзапросы и CTE*

фев'24
<hr>

### Структура каталога

```
homework_04
├── hw_subqueries_tasks-188-274338.sql  - Домашняя работа запросами SQL
├── ReadMe.md                           - Данный файл
└── _work                               - Рабочая папка с материалами /оставлена для своих задач автора/

```

<hr>

[Ссылка на файл с ДЗ04](hw_subqueries_tasks-188-274338.sql)
<hr>

### Описание ДЗ

**Цель:**
В этом ДЗ вы научитесь писать подзапросы и CTE.

**Описание/Пошаговая инструкция выполнения домашнего задания:**

Для всех заданий, где возможно, сделайте два варианта запросов:

через вложенный запрос
через WITH (для производных таблиц)

Напишите запросы:
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), и не сделали ни одной продажи 04 июля 2015 года. Вывести ИД сотрудника и его полное имя. Продажи смотреть в таблице Sales.Invoices.
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. Вывести: ИД товара, наименование товара, цена.
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей из Sales.CustomerTransactions. Представьте несколько способов (в том числе с CTE).
4. Выберите города (ид и название), в которые были доставлены товары, входящие в тройку самых дорогих товаров, а также имя сотрудника, который осуществлял упаковку заказов (PackedByPersonID).

**Опционально:**
Объясните, что делает и оптимизируйте запрос:
```SQL
SELECT
Invoices.InvoiceID,
Invoices.InvoiceDate,
(SELECT People.FullName
FROM Application.People
WHERE People.PersonID = Invoices.SalespersonPersonID
) AS SalesPersonName,
SalesTotals.TotalSumm AS TotalSummByInvoice,
(SELECT SUM(OrderLines.PickedQuantityOrderLines.UnitPrice)
FROM Sales.OrderLines
WHERE OrderLines.OrderId = (SELECT Orders.OrderId
FROM Sales.Orders
WHERE Orders.PickingCompletedWhen IS NOT NULL
AND Orders.OrderId = Invoices.OrderId)
) AS TotalSummForPickedItems
FROM Sales.Invoices
JOIN
(SELECT InvoiceId, SUM(QuantityUnitPrice) AS TotalSumm
FROM Sales.InvoiceLines
GROUP BY InvoiceId
HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC
```

Можно двигаться как в сторону улучшения читабельности запроса, так и в сторону упрощения плана\ускорения.

Сравнить производительность запросов можно через ```SET STATISTICS IO```, ```TIME ON```.

Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы).

Напишите ваши рассуждения по поводу оптимизации.
<hr>

**Критерии оценки:** Статус "Принято" ставится если написаны SQL-запросы, выводящие правильные результаты в соответствии с заданиями.