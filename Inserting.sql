INSERT INTO HumanResources.Employee
VALUES('John','Lark','3,Major Way','11-362-4481-444-726','Senior Executive'),
	  ('Natasha','Stacey','1,Collins Drive','37-471-2844-974-462','Event Manager'),
	  ('Martha','Daniels','5,Whites Way','13-442-4677-374-663','Senior Event Manager') 



INSERT INTO Management.Events
VALUES('Howard Weds Martha',1,1000,500,25,'2019-04-19','2019-04-21','Civic Centre',200),
	  ('Christines 18th Birthday',2,1001,501,20,'2019-04-18','2019-04-19','Showman Hall',90),
	  ('Ashleys Dinner Hosting',3,1002,502,20,'2019-05-01','2019-05-02','Showman Hall',60) 


INSERT INTO Management.Payments
VALUES(10,DEFAULT,'2019-04-19','2019-04-18',1,DEFAULT,ENCRYPTBYKEY(KEY_GUID('CreditCardNo_EncryptKey'),'2343675478956478'),'Howard Christian','2020-01-01',NULL,DEFAULT),
	  (11,DEFAULT,'2019-04-18','2019-04-16',1,DEFAULT,ENCRYPTBYKEY(KEY_GUID('CreditCardNo_EncryptKey'),'2434375628797458'),'Ashley Babe','2020-03-01',NULL,DEFAULT),
	  (12,DEFAULT,'2019-05-01',NULL,2,NULL,DEFAULT,NULL,NULL,NULL,DEFAULT)


INSERT INTO Event.Customers
VALUES('Howard Christian','3,Kings Way','V.I','Lagos','11-345-2534-573-458'),
	  ('Christine Kate','3,Gbadamosi Street','Ikeja','Lagos','22-431-3355-667-458'),
	  ('Ashley Babe','5,Collins Way','V.I','Lagos','45-543-6734-638-648')


INSERT INTO Event.EventTypes
VALUES('Wedding',5000),
	  ('Birthdays',4500),
	  ('Dinner Hosting',3500),
	  ('Wake Keep',3000)



INSERT INTO Management.PaymentMethods
VALUES('Credit Card'),
	  ('Cheque'),
	  ('Cash')





















