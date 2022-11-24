-- SQLite3
-- Create pivot views of tables.

-- Run the queries below.  The first creates tblFields.
-- The second and third create sql to create Pivot views - just copy/paste the sql to actually
-- create the views.  If you are using the simple (data-only) pivots, you can `drop table tblFields;`

-- From
-- tbl
-- id fldA fldB fldC
-- 1  1    2    3
-- 2  4    5    6

-- To:
-- tbl_Pivot
-- id fld val
-- 1  fldA 1
-- 1  fldB 2
-- 1  fldC 3
-- 2  fldA 4
-- 2  fldB 5
-- 2  fldC 6

-- Field spec table, with some additional fields for coding. You can ignore those if you want.
CREATE TABLE tblFields AS
SELECT m.name AS tblName, 
       p.name AS colName,
       p.type AS colType,
       p.[notnull] AS colNotNull,
       p.pk AS colPK,
       p.dflt_value AS colDefault,
       IIF(INSTR(p.type,'CHAR')>0,'"',' ') AS colDelimiter,
       p.name AS colDisplayTitle,
       p.cid AS colSortOrder,
       p.cid AS colDisplaySortOrder,
       1 AS colDisplayOnGridView,
       1 AS colDisplayOnFormView,
      'text' AS colControlType,
       0 AS colEnabled
FROM sqlite_master m
LEFT OUTER JOIN pragma_table_info((m.name)) p
     ON m.name <> p.name
WHERE m.name <> 'sqlite_sequence'
	AND p.name IS NOT NULL
ORDER BY m.name, p.cid;



-- Simple Pivot, just data.

SELECT 'CREATE VIEW ' || e.tblName || '_Pivot AS ' || char(10) ||
SUBSTR(e.statement, 1,LENGTH(e.statement)-6) || char(10)
AS solution
FROM 
(
 SELECT d.tblName, GROUP_CONCAT(e.sql, char(10)) AS statement
 FROM tblFields d
 LEFT JOIN 
 (
  SELECT b.tblName, b.pkField, b.colName, 'SELECT ''' || b.tblName  || ''' AS tbl, ' || b.pkField || ' AS id, ''' ||  b.colName || ''' AS fld, ' ||
  b.colName || ' AS val FROM ' || b.tblName || ' UNION ' AS sql
  FROM
  (
   SELECT m.*, 
   (
    SELECT a.colName 
    FROM tblFields a 
    WHERE a.tblName=m.tblName AND a.colPK = 1 LIMIT 1
   ) AS pkField
   FROM tblFields m
  ) b
  GROUP BY b.tblName, b.pkField, b.colName 
  ORDER BY b.tblName, b.pkField, b.colName
 ) e ON d.tblName = e.tblName AND d.colName = e.colName
 GROUP BY d.tblName
 ORDER BY d.tblName
) e;



-- Complex Pivot, data plus field specs

SELECT 'CREATE VIEW ' || e.tblName || '_Pivot_Specs AS ' || char(10) ||
'SELECT a.* , b.* ' || char(10) ||
'FROM ' || char(10) || 
'( ' || char(10) || 
SUBSTR(e.statement, 1,LENGTH(e.statement)-6) || char(10) || 
') a ' || char(10) || 
'LEFT JOIN tblFields b ON a.tbl = b.tblName AND a.fld = b.colName;' || char(10) 
AS solution
FROM 
(
 SELECT d.tblName, GROUP_CONCAT(e.sql, char(10)) AS statement
 FROM tblFields d
 LEFT JOIN 
 (
  SELECT b.tblName, b.pkField, b.colName, 'SELECT ''' || b.tblName  || ''' AS tbl, ' || b.pkField || ' AS id, ''' ||  b.colName || ''' AS fld, ' ||
  b.colName || ' AS val FROM ' || b.tblName || ' UNION ' AS sql
  FROM
  (
   SELECT m.*, 
   (
    SELECT a.colName 
    FROM tblFields a 
    WHERE a.tblName=m.tblName AND a.colPK = 1 LIMIT 1
   ) AS pkField
   FROM tblFields m
  ) b
  GROUP BY b.tblName, b.pkField, b.colName 
  ORDER BY b.tblName, b.pkField, b.colName
 ) e ON d.tblName = e.tblName AND d.colName = e.colName
 GROUP BY d.tblName
 ORDER BY d.tblName
) e;
