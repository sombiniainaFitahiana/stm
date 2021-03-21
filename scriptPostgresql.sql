sudo -i -u postgres
psql CREATE DATABASE stm;
psql;
CREATE ROLE admin_stm LOGIN password '123456';
ALTER DATABASE stm OWNER TO admin_stm;
\q
exit
psql -U admin_stm stm
123456

CREATE SEQUENCE CLIENT_SEQ INCREMENT BY 1 START 1;
CREATE TABLE CLIENT (
    IDCLIENT VARCHAR DEFAULT 'CLT' || NEXTVAL('CLIENT_SEQ'),
    PSEUDO VARCHAR NOT NULL,
    CIN VARCHAR (12) NOT NULL UNIQUE,
    NUMERO VARCHAR (13) NOT NULL UNIQUE,
    MOTDEPASSE VARCHAR(40) NOT NULL,
    PRIMARY KEY (IDCLIENT)
);

CREATE SEQUENCE ADMIN_SEQ INCREMENT BY 1 START 1;
CREATE TABLE ADMIN (
    IDADMIN VARCHAR DEFAULT 'ADMIN' || NEXTVAL('ADMIN_SEQ'),
    PSEUDO VARCHAR NOT NULL UNIQUE,
    MOTDEPASSE VARCHAR(40) NOT NULL,
    PRIMARY KEY (IDADMIN)
);

CREATE SEQUENCE OFFRE_SEQ INCREMENT BY 1 START 1;
CREATE TABLE OFFRE (
    IDOFFRE VARCHAR DEFAULT 'OFR' || NEXTVAL('OFFRE_SEQ'),
    NOMOFFRE VARCHAR NOT NULL,
    DESCRIPTION TEXT NOT NULL,
    COUT DECIMAL(8,2) NOT NULL, -- ARIARY
    VALIDITE INTEGER NOT NULL, -- JOUR
    PRIMARY KEY (IDOFFRE)
);

CREATE SEQUENCE APPEL_SEQ INCREMENT BY 1 START 1;
CREATE TABLE APPEL(
    IDAPPEL VARCHAR DEFAULT 'APL' || NEXTVAL('APPEL_SEQ'),
    IDCLIENT VARCHAR NOT NULL,
    NUMERO VARCHAR (13) NOT NULL,
    DUREE INTEGER NOT NULL, -- EN SECONDE
    DATEAPPEL TIMESTAMP NOT NULL,
    PRIMARY KEY (IDAPPEL),
    FOREIGN KEY (IDCLIENT) REFERENCES CLIENT (IDCLIENT)
);

CREATE TABLE ACHATOFFRE(
    IDCLIENT VARCHAR NOT NULL,
    IDOFFRE VARCHAR NOT NULL,
    DATEACHAT TIMESTAMP NOT NULL,
    FOREIGN KEY (IDCLIENT) REFERENCES CLIENT (IDCLIENT),
    FOREIGN KEY (IDOFFRE) REFERENCES OFFRE (IDOFFRE)
);

CREATE SEQUENCE TRANSACTION_SEQ INCREMENT BY 1 START 1;
CREATE TABLE TRANSACTION (
    IDTRANSACTION VARCHAR DEFAULT 'TRCT' || NEXTVAL('TRANSACTION_SEQ'),
    IDCLIENT VARCHAR NOT NULL,
    MONTANT DECIMAL(12) NOT NULL,
    DATETRANSACTION TIMESTAMP NOT NULL,
    ETAT BOOLEAN NOT NULL,
    PRIMARY KEY(IDTRANSACTION),
    FOREIGN KEY (IDCLIENT) REFERENCES CLIENT (IDCLIENT)
);

CREATE TABLE CREDIT (
    IDCREDIT INTEGER GENERATED ALWAYS AS IDENTITY,
    IDCLIENT VARCHAR NOT NULL,
    MONTANT DECIMAL(12) NOT NULL,
    PRIMARY KEY (IDCREDIT),
    FOREIGN KEY (IDCLIENT) REFERENCES CLIENT (IDCLIENT)
);

INSERT INTO CLIENT (PSEUDO, CIN, NUMERO, MOTDEPASSE) 
VALUES  ('Rakoto', '111111111111', '+261301212568', '123456'), 
        ('Rasoa', '222222222222', '+261302678935', '123456');

INSERT INTO ADMIN (PSEUDO, MOTDEPASSE)
VALUES  ('Nantenaina', '123456'),
        ('Sombiniaina', '123456'),
        ('ITU', '123456');

INSERT INTO OFFRE (NOMOFFRE, DESCRIPTION, COUT, VALIDITE) 
VALUES  ('Bomba be', 'Offre bomba be ry vahoaka malagasy aaaa', 1000, 7),
        ('Bomba kely', 'Offre bomba kely ry vahoaka malagasy aaaa', 500, 3);

INSERT INTO APPEL (IDCLIENT, NUMERO, DUREE, DATEAPPEL) 
VALUES  ('CLT1', '+261302678935', 0, '2021-3-18 8:00:00'),
        ('CLT1', '+261302678935', 60, '2021-3-18 8:04:00'),
        ('CLT1', '+261332678935', 50, '2021-3-18 10:00:00'),
        ('CLT1', '+512302678935', 20, '2021-3-18 11:00:00');    

INSERT INTO ACHATOFFRE (IDCLIENT, IDOFFRE, DATEACHAT)
VALUES ('CLT1', 'OFR1', '2021-3-17 7:00:00'),
       ('CLT1', 'OFR2', '2021-3-18 7:00:00'),
       ('CLT2', 'OFR1', '2021-3-18 8:00:00');

INSERT INTO TRANSACTION (IDCLIENT, MONTANT, DATETRANSACTION , ETAT)
VALUES ('CLT1', 2000, '2021-3-17 6:00:00', TRUE),
       ('CLT1', -500, '2021-3-17 7:00:00', FALSE);

CREATE VIEW APPELSORTANT 
    AS SELECT *, CASE DUREE WHEN 0 THEN 'Sortant manque' ELSE 'Sortant' END AS TYPE FROM APPEL;

CREATE VIEW APPELENTRANT AS
    SELECT 
        A.IDAPPEL,
        C.IDCLIENT, 
        C.NUMERO, 
        A.DUREE, 
        A.DATEAPPEL,
        CASE DUREE WHEN 0 THEN 'Entrant manque' ELSE 'Entrant' END AS TYPE
    FROM 
        APPEL A JOIN 
        CLIENT C ON A.NUMERO = C.NUMERO;

CREATE VIEW SYNTHAPPEL AS 
    SELECT * FROM APPELSORTANT UNION SELECT * FROM APPELENTRANT;

CREATE VIEW HISTORIQUESAPPELS AS
    SELECT IDCLIENT, NUMERO, COUNT(*) NOMBRE, DATE(DATEAPPEL) DATE FROM SYNTHAPPEL GROUP BY DATE(DATEAPPEL), NUMERO, IDCLIENT;

CREATE VIEW JOUR AS SELECT * FROM (VALUES (1),(2),(3),(4),(5),(6),(7)) AS JOUR(JOUR);

CREATE VIEW MOIS AS SELECT * FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) AS MOIS(MOIS);

CREATE OR REPLACE VIEW STATOFFREJOURNALIER AS
    SELECT 
	IDOFFRE,
	NOMOFFRE,
	CAST(JOUR AS VARCHAR) AS LIBELE, 
	CAST(COALESCE(NOMBRE, 0) AS INTEGER) AS NOMBRE 
FROM 
	(SELECT * FROM JOUR,OFFRE) R1 NATURAL LEFT JOIN 
	(SELECT IDOFFRE, EXTRACT(DOW FROM DATEACHAT) JOUR, COUNT(*) NOMBRE FROM ACHATOFFRE GROUP BY EXTRACT(DOW FROM DATEACHAT), IDOFFRE) R2;

CREATE OR REPLACE VIEW STATOFFREMENSUEL AS
    SELECT 
	IDOFFRE,
	NOMOFFRE,
	CAST(MOIS AS VARCHAR) AS LIBELE, 
	CAST(COALESCE(NOMBRE, 0) AS INTEGER) AS NOMBRE 
FROM 
	(SELECT * FROM MOIS,OFFRE) R1 NATURAL LEFT JOIN 
	(SELECT IDOFFRE, EXTRACT(MONTH FROM DATEACHAT) MOIS, COUNT(*) NOMBRE FROM ACHATOFFRE GROUP BY EXTRACT(MONTH FROM DATEACHAT), IDOFFRE) R2;

CREATE VIEW DEPOTNONVALIDER AS 
    SELECT * FROM TRANSACTION WHERE ETAT = FALSE; 

CREATE VIEW SOLDEMOBILEMONEY AS
    SELECT IDCLIENT, SUM(MONTANT) SOLDEMOBILEMONEY FROM TRANSACTION GROUP BY IDCLIENT; 

CREATE VIEW SOLDE AS
    SELECT IDCLIENT, MONTANT FROM CREDIT NATURAL JOIN (SELECT MAX(IDCREDIT) AS IDCREDIT FROM CREDIT GROUP BY (IDCREDIT)) R;

CREATE VIEW COMPTE AS
    SELECT 
        CLIENT.*, 
        COALESCE(SOLDE.MONTANT, 0) AS CREDIT,  
        COALESCE(SOLDEMOBILEMONEY.SOLDEMOBILEMONEY, 0) AS  SOLDEMOBILEMONEY
    FROM 
        CLIENT NATURAL LEFT JOIN 
        SOLDE NATURAL LEFT JOIN 
        SOLDEMOBILEMONEY;



