create database ShowmanHouse
GO
create schema Management
GO
create schema HumanResources
GO
create schema Event
GO


create table HumanResources.Employee
(
EmployeeID int IDENTITY(1,1) PRIMARY KEY ,
FirstName varchar(20) NOT NULL,
LastName varchar(22) NOT NULL,
Address varchar(60) NOT NULL,
Phone varchar(21) NOT NULL CONSTRAINT chkPhone 
CHECK(Phone LIKE '[0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9]'),
Title varchar(55) CONSTRAINT chkTitle 
CHECK(Title IN ('Executive','Senior Executive','Management Trainee','Event Manager','Senior Event Manager'))
)

create table Management.Events
(
EventID int IDENTITY(10,1) PRIMARY KEY,
EventName varchar(30) NOT NULL,
EmployeeID int FOREIGN KEY References  HumanResources.Employee(EmployeeID),
CustomerID int FOREIGN KEY  References Event.Customers(CustomerID),
EventTypeID int CONSTRAINT fkEventTypeID FOREIGN KEY References Event.EventTypes(EventTypeID),
StaffRequired int CONSTRAINT chkStaffRequired 
CHECK(StaffRequired>0),
StartDate datetime NOT NULL CONSTRAINT chkStartDate
CHECK(StartDate>getdate()),
EndDate datetime NOT NULL CONSTRAINT chkEndDate
CHECK(EndDate>getdate()),
Location varchar(40) NOT NULL,
NoOfPeople int NOT NULL CONSTRAINT chkNoOfPeople
CHECK(NoOfPeople>=50),
CONSTRAINT chkStartDate2
CHECK (StartDate<EndDate)
)

/**TO ADD REFERENTIAL INTEGRITY CONSTARINTS**/
ALTER TABLE Management.Events ADD CONSTRAINT fkEmployeeID FOREIGN KEY(EmployeeID)
REFERENCES HumanResources.Employee(EmployeeID) ON DELETE NO ACTION ON UPDATE CASCADE 


ALTER TABLE Management.Events ADD CONSTRAINT fkCustomerID FOREIGN KEY(CustomerID)
REFERENCES Event.Customers(CustomerID) ON DELETE NO ACTION ON UPDATE CASCADE


create table Management.Payments 
(
PaymentID int IDENTITY(100,1) PRIMARY KEY,
EventID int FOREIGN KEY References Management.Events(EventID),
EventTypeID int FOREIGN KEY References Event.EventTypes(EventTypeID) DEFAULT NULL,
StartDate datetime,
PaymentDate datetime,
PaymentMethodID int FOREIGN KEY References Management.PaymentMethods(PaymentMethodID),
PaymentStatus varchar(7) DEFAULT NULL,
CreditCardNumber varchar(150),
CardHoldersName varchar(30),
CreditCardExpDate datetime CONSTRAINT chkCrdExpDate
CHECK(CreditCardExpDate>getdate()),
ChequeNo int,
PaymentAmount int DEFAULT NULL,
CONSTRAINT chkPaymentDate
CHECK(PaymentDate<=StartDate)
)
/**TO DEFINE THE PAYMENT AMOUNT COLUMN**/
GO
create TRIGGER GetPaymentAmt ON Management.Payments
AFTER INSERT AS
SET NOCOUNT ON;
BEGIN
	WITH Temp_CTE (EventID,NoOfPeople,ChargePerPerson,PaymentAmt) AS
	(select me.EventID,me.NoOfPeople,ee.ChargePerPerson,PaymentAmt=me.NoOfPeople*ee.ChargePerPerson 
	FROM Inserted ins JOIN Management.Events me ON ins.EventID=me.EventID
	JOIN Event.EventTypes ee ON me.EventTypeID=ee.EventTypeID)

	UPDATE Management.Payments
	SET [Management].[Payments].[PaymentAmount]=
	(select Temp_CTE.PaymentAmt FROM Temp_CTE WHERE Temp_CTE.EventID=Management.Payments.EventID)
END

/**TO AUTOMATICALLY SET THE EVENT TYPEID IN THE PAYMENTS TABLE**/
GO
create TRIGGER SetEventTypeID ON Management.Payments
AFTER INSERT AS
SET NOCOUNT ON;
WITH EventTypeID_CTE (EventID,EventTypeID) AS
(SELECT EventID,EventTypeID FROM Management.Events)
UPDATE Management.Payments
SET EventTypeID=(select EventTypeID FROM EventTypeID_CTE WHERE Management.Payments.EventID=EventTypeID_CTE.EventID)


--/TO AUTOMATICALLLY SET THE PAYMENT STATUS COLUMN/
GO
CREATE TRIGGER SetPaymentStatus ON Management.Payments
AFTER INSERT
AS
SET NOCOUNT ON;
BEGIN
WITH Status_CTE(PaymentID,PaymentDate,PaymentStatus) AS
(select PaymentID,PaymentDate,IIF(PaymentDate IS NULL,'Pending',IIF(PaymentDate IS NOT NULL,'Paid','')) AS PaymentStatus FROM inserted)

	UPDATE Management.Payments
	SET PaymentStatus=(select Status_CTE.PaymentStatus FROM Status_CTE WHERE Status_CTE.PaymentID=Management.Payments.PaymentID)
END


GO
CREATE TRIGGER UpdatePaymentStatus ON Management.Payments
FOR UPDATE
AS
SET NOCOUNT ON;
BEGIN
IF UPDATE(PaymentDate)
BEGIN
	WITH Status_CTE(PaymentID,PaymentDate,PaymentStatus) AS
	(select PaymentID,PaymentDate,IIF(PaymentDate IS NULL,'Pending',IIF(PaymentDate IS NOT NULL,'Paid','')) AS PaymentStatus FROM Management.Payments)

	UPDATE Management.Payments
	SET PaymentStatus=(select Status_CTE.PaymentStatus FROM Status_CTE WHERE Status_CTE.PaymentID=Management.Payments.PaymentID)
END
END

/**TO ADD REFERENTIAL CONSTRAINTS**/
ALTER TABLE Management.Payments ADD CONSTRAINT fkEventID FOREIGN KEY(PaymentMethodID)
REFERENCES Management.PaymentMethods(PaymentMethodID) ON DELETE NO ACTION ON UPDATE CASCADE


ALTER TABLE Management.Payments ADD CONSTRAINT fkEventTypeID FOREIGN KEY(EventTypeID)
REFERENCES Event.EventTypes(EventTypeID) ON DELETE NO ACTION ON UPDATE CASCADE


create table Event.Customers
(
CustomerID int IDENTITY(1000,1) PRIMARY KEY,
Name varchar(30) NOT NULL,
Address varchar(55) NOT NULL,
City varchar(18) NOT NULL,
State varchar(20) NOT NULL,
Phone varchar(21) NOT NULL CONSTRAINT chkPhone 
CHECK(PHONE LIKE '[0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9]')
)

create table Event.EventTypes
(
EventTypeID int IDENTITY(500,1) PRIMARY KEY,
Description varchar(55) NOT NULL,
ChargePerPerson int CONSTRAINT chkChrgPerPerson
CHECK(ChargePerPerson>0)
)

create table Management.PaymentMethods
(
PaymentMethodID int IDENTITY(1,1) PRIMARY KEY,
Description varchar(55) CONSTRAINT chkDesc 
CHECK(Description IN('Cash','Cheque','Credit Card'))
)

/**CREATING INDEXES**/--/FOR THE FIRST INDEX/
create UNIQUE CLUSTERED INDEX Ix_EventID ON Management.Events
(EventID)

CREATE INDEX Ix_CustomerEvent ON Management.Events
(CustomerID) INCLUDE (StartDate)

--/FOR THE SECOND INDEX/
CREATE INDEX IX_EventPayment ON Management.Payments
(EventID) INCLUDE (PaymentStatus)

--/FOR THE THIRD INDEX/
create INDEX IX_EventDetails ON Management.Events
(StaffRequired)



/**CREATING RELATIONSHIPS BETWEEN TABLES**/
/**EventDetails View**/
GO
create VIEW Management.vwEventDetails WITH SCHEMABINDING AS
SELECT me.EventID,me.CustomerID,ec.Name AS 'CustomerName',mp.PaymentID,
mp.PaymentMethodID,mp.PaymentAmount,mp.PaymentStatus,ee.EventTypeID,me.EventName,me.Location,me.StartDate,me.EndDate,
mp.PaymentDate
FROM Management.Events me JOIN Management.Payments mp ON
me.EventID=mp.EventID JOIN Event.EventTypes ee ON mp.EventTypeID=ee.EventTypeID JOIN Event.Customers ec
ON me.CustomerID=ec.CustomerID
GO

select * FROM Management.vwEventDetails

--/TO INDEX THE VIEW/
CREATE UNIQUE CLUSTERED INDEX Ix_vwEventID ON Management.vwEventDetails
(EventID) 

CREATE NONCLUSTERED INDEX Ix_vwCustomerID ON Management.vwEventDetails
(CustomerID)

CREATE NONCLUSTERED INDEX Ix_vwEventName ON Management.vwEventDetails
(EventName,Location) INCLUDE (PaymentAmount) 

select * FROM Management.vwEventDetails
--/CREATING LOGINS/

CREATE LOGIN Chris WITH PASSWORD = N'passwordchris'
EXEC sp_addsrvrolemember 'Chris','sysadmin'

CREATE LOGIN William WITH PASSWORD = N'passwordwilliam'
EXEC sp_addrolemember 'William','dbcreator'

CREATE LOGIN Sara WITH PASSWORD = N'passwordsara'
EXEC sp_addrolemember 'Sara','dbcreator'

CREATE LOGIN Sam WITH PASSWORD = N'passwordsam'
EXEC sp_addrolemember 'Sam','dbcreator'

--/ENCRYPTION/

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'NEWMASTERKEY'
select * from sys.master_key_passwords

/*Creating sql server certificate on CreditCardNumber*/
USE ShowmanHouse
GO
CREATE CERTIFICATE CreditCardNumber
	WITH SUBJECT='CreditCardNumber';
GO

/*Creating Sql Server Symentric Keys on CreditCardNumber*/
CREATE SYMMETRIC KEY CreditCardNo_EncryptKey
	WITH ALGORITHM = AES_256
	ENCRYPTION BY CERTIFICATE CreditCardNumber;
GO

/*Open the symetric key with which to encrypt the data*/
OPEN SYMMETRIC KEY CreditCardNo_EncryptKey
	DECRYPTION BY CERTIFICATE CreditCardNumber
GO

/**AUTOMATED TASKS--**/

/**AUTOMATIC BACKUP OF DATABASE**/
USE ShowmanHouse
GO
BACKUP DATABASE [ShowmanHouse]
TO DISK ='C:\DATA\ShowmanHouse_Backup.bak'
WITH DESCRIPTION='FullBackupOfShowmanHouse'
GO

/**FOR THE EMPLOYEES WHO HAVE MANAGED AN EVENT**/
DECLARE @EmployeeID varchar(50),@FirstName varchar(25),@LastName varchar(25),@EventID varchar(50),@Name varchar(25)
DECLARE EmpDetail CURSOR
LOCAL SCROLL STATIC
FOR
	select he.EmployeeID,he.FIrstName,he.LastName,me.EventID,me.EventName 
	FROM HumanResources.Employee he JOIN Management.Events me ON he.EmployeeID=me.EmployeeID 
	WHERE convert(varchar(25),DATEPART(month,me.StartDate))+','+convert(varchar(25),DATEPART(year,me.StartDate))=
	convert(varchar(25),DATEPART(month,getdate()))+','+convert(varchar(25),DATEPART(year,getdate()))
OPEN EmpDetail
FETCH NEXT FROM EmpDetail
	INTO @EmployeeID,@FirstName,@LastName,@EventID,@Name
	PRINT 'Employee:'+@EmployeeID+' '+@FirstName+' '+@LastName+' '+'Managed Event: '+@EventID+' '+@Name
WHILE @@FETCH_STATUS=0
BEGIN
	FETCH NEXT FROM EmpDetail
	INTO @EmployeeID,@FirstName,@LastName,@EventID,@Name
	PRINT 'Employee:'+@EmployeeID+' '+@FirstName+' '+@LastName+' '+'Managed Event: '+@EventID+' '+@Name
END
CLOSE EmpDetail

DEALLOCATE EmpDetail










































































