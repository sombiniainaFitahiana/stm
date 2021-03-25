sudo -i -u postgres
psql CREATE DATABASE stm;
psql;
CREATE ROLE admin_stm LOGIN password '123456';
ALTER DATABASE stm OWNER TO admin_stm;
\q
exit
psql -U admin_stm stm
123456

CREATE TABLE FORFAIT(
    IDFORFAIT INTEGER GENERATED ALWAYS AS IDENTITY,
    NOM VARCHAR NOT NULL UNIQUE,
    UNITE VARCHAR NOT NULL,
    PRIMARY KEY (IDFORFAIT)
);

CREATE SEQUENCE OFFRE_SEQ INCREMENT BY 1 START 1;
CREATE TABLE OFFRE (
    IDOFFRE VARCHAR DEFAULT 'OFR' || NEXTVAL('OFFRE_SEQ'),
    NOMOFFRE VARCHAR NOT NULL UNIQUE,
    DESCRIPTION TEXT NOT NULL,
    PRIMARY KEY (IDOFFRE)
);

CREATE TABLE HORAIRE (
    IDOFFRE VARCHAR NOT NULL,
    DEBUT TIME NOT NULL,
    FIN TIME,
    FOREIGN KEY (IDOFFRE) REFERENCES OFFRE (IDOFFRE)
);

CREATE TABLE OFFREFORFAIT (
    IDOFFRE VARCHAR NOT NULL,
    IDFORFAIT INTEGER NOT NULL,
    FOREIGN KEY (IDOFFRE) REFERENCES OFFRE (IDOFFRE),
    FOREIGN KEY (IDFORFAIT) REFERENCES FORFAIT(IDFORFAIT)
);
CREATE UNIQUE INDEX UK_OFFRE_FORFAIT ON OFFREFORFAIT (IDOFFRE, IDFORFAIT);

CREATE TABLE PRIXOFFRE(
    IDOFFRE VARCHAR NOT NULL,
    IDFORFAIT INTEGER NOT NULL,
    PRIX INTEGER NOT NULL,
    VALIDITE INTEGER,
    COUT DECIMAL(7,3)[] NOT NULL,
    FOREIGN KEY (IDOFFRE) REFERENCES OFFRE (IDOFFRE),
    FOREIGN KEY (IDFORFAIT) REFERENCES FORFAIT(IDFORFAIT)
);

CREATE TABLE ACHATOFFRE(
    IDCLIENT VARCHAR NOT NULL,
    IDOFFRE VARCHAR NOT NULL,
    DATEACHAT TIMESTAMP NOT NULL,
    FOREIGN KEY (IDCLIENT) REFERENCES CLIENT (IDCLIENT),
    FOREIGN KEY (IDOFFRE) REFERENCES OFFRE (IDOFFRE)
);
CREATE UNIQUE INDEX UK_ACHATOFFRE ON ACHATOFFRE (IDCLIENT, IDOFFRE, DATEACHAT);

CREATE SEQUENCE CLIENT_SEQ INCREMENT BY 1 START 1;
CREATE TABLE CLIENT (
    IDCLIENT VARCHAR DEFAULT 'CLT' || NEXTVAL('CLIENT_SEQ'),
    NOMCLIENT VARCHAR NOT NULL,
    CIN VARCHAR (12) NOT NULL,
    NUMERO VARCHAR (13) NOT NULL UNIQUE,
    MOTDEPASSE VARCHAR(40) NOT NULL,
    PRIMARY KEY (IDCLIENT)
);
CREATE UNIQUE INDEX UK_CLIENT ON CLIENT (NUMERO, CIN);


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

CREATE TABLE DATA (
    IDCLIENT VARCHAR NOT NULL,
    IDOFFRE VARCHAR NOT NULL,
    IDFORFAIT INTEGER NOT NULL,
    DATA DECIMAL (14, 2) NOT NULL,
    DATEEXPIRATION TIMESTAMP,
    FOREIGN KEY (IDCLIENT) REFERENCES CLIENT (IDCLIENT),
    FOREIGN KEY (IDFORFAIT) REFERENCES FORFAIT(IDFORFAIT)
);
CREATE UNIQUE INDEX UK_DATA ON DATA (IDCLIENT, IDOFFRE, IDFORFAIT);

CREATE OR REPLACE FUNCTION CLIENT_TRIGGER() RETURNS TRIGGER AS $TRG$
    BEGIN
        INSERT INTO DATA (IDCLIENT, IDOFFRE, IDFORFAIT, DATA) VALUES (NEW.IDCLIENT, 'DEFAUT', 1, 0);
        INSERT INTO DATA (IDCLIENT, IDOFFRE, IDFORFAIT, DATA) VALUES (NEW.IDCLIENT, 'MOBILEMONEY', 1, 0);
        RETURN NEW;
    END;
$TRG$ LANGUAGE plpgsql;

CREATE TRIGGER CLIENT_TRIGGER AFTER INSERT ON CLIENT
    FOR EACH ROW EXECUTE PROCEDURE CLIENT_TRIGGER();


CREATE VIEW COMPTE AS
SELECT 
        CLIENT.*, 
        MAX(CREDIT) AS CREDIT,
        MAX(MOBILEMONEY) AS MOBILEMONEY
        FROM 
                CLIENT NATURAL JOIN 
                (SELECT IDCLIENT, 
                        CASE DATA.IDOFFRE WHEN 'DEFAUT' THEN DATA END AS CREDIT, 
                        CASE DATA.IDOFFRE WHEN 'MOBILEMONEY' THEN DATA END AS MOBILEMONEY
                FROM 
                        DATA WHERE IDOFFRE='DEFAUT' OR IDOFFRE='MOBILEMONEY') R 
        GROUP BY IDCLIENT, NOMCLIENT, CIN, NUMERO, MOTDEPASSE;


CREATE VIEW JOUR AS SELECT * FROM (VALUES (1) , (2), (3) , (4), (5), (6), (7)) AS JOUR (JOUR);
CREATE VIEW MOIS AS SELECT * FROM (VALUES (1) , (2), (3) , (4), (5), (6), (7), (8), (9), (10), (11), (12)) AS MOIS (MOIS);

CREATE OR REPLACE VIEW STATOFFREJOURNALIER AS
    SELECT 
        IDOFFRE,
        CAST(JOUR AS VARCHAR) AS LIBELE, 
        CAST(COALESCE(NOMBRE, 0) AS INTEGER) AS NOMBRE 
    FROM JOUR,OFFRE NATURAL LEFT JOIN
        (SELECT IDOFFRE, EXTRACT(DOW FROM DATEACHAT) JOUR, COUNT(*) NOMBRE FROM ACHATOFFRE GROUP BY IDOFFRE, EXTRACT(DOW FROM DATEACHAT)) R;

CREATE OR REPLACE VIEW STATOFFREMENSUEL AS
    SELECT CAST(MOIS AS VARCHAR) AS LIBELE, CAST(COALESCE(NOMBRE, 0) AS INTEGER) AS NOMBRE FROM MOIS NATURAL LEFT JOIN (SELECT EXTRACT(MONTH FROM DATEACHAT) MOIS, COUNT(*) NOMBRE FROM ACHATOFFRE GROUP BY EXTRACT(MONTH FROM DATEACHAT)) R;



SELECT * FROM JOUR,OFFRE WHERE IDOFFRE != 'MOBILEMONEY' AND IDOFFRE !='DEFAUT';

SELECT IDOFFRE, EXTRACT(DOW FROM DATEACHAT) JOUR, COUNT(*) NOMBRE FROM ACHATOFFRE GROUP BY IDOFFRE, EXTRACT(DOW FROM DATEACHAT);