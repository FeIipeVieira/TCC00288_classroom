DO $$ BEGIN
 PERFORM drop_functions();
 PERFORM drop_tables();
END $$;
create table venda(
 ano_mes int not null,
 unidade int,
 vendedor int,
 produto int,
 valor float
);
insert into venda values(202001,1,1,10,100.0);
insert into venda values(202001,1,2,10,200.0);
insert into venda values(202001,1,3,10,300.0);
insert into venda values(202002,1,1,10,200.0);
insert into venda values(202002,1,2,10,300.0);
insert into venda values(202002,1,3,10,500.0);
insert into venda values(202003,1,1,10,900.0);
insert into venda values(202003,1,2,10,200.0);
insert into venda values(202003,1,3,10,500.0);
insert into venda values(202004,1,1,10,200.0);
insert into venda values(202004,1,2,10,150.0);
insert into venda values(202004,1,3,10,500.0);
insert into venda values(202005,1,1,10,500.0);
insert into venda values(202005,1,2,10,300.0);
insert into venda values(202005,1,3,10,700.0);
insert into venda values(202006,1,1,10,200.0);
insert into venda values(202006,1,2,10,200.0);
insert into venda values(202006,1,3,10,200.0);
-----------------------------------------
--
-- Acrescente seu código a partir daqui
-----------------------------------------

-- QUESTÃO 1

CREATE OR REPLACE FUNCTION produto (matriz1 float[][], matriz2 float[][])
    RETURNS float[][]
    AS $$
    DECLARE
        qtdLinMat1 integer;
        qtdColMat1 integer;
        qtdLinMat2 integer;
        qtdColMat2 integer;
        matFinal float[][];
    BEGIN
        SELECT array_length(matriz1, 1) INTO qtdLinMat1;
        SELECT array_length(matriz1, 2) INTO qtdColMat1;
        SELECT array_length(matriz2, 1) INTO qtdLinMat2;
        SELECT array_length(matriz2, 2) INTO qtdColMat2;
        SELECT array_fill(0, ARRAY[qtdLinMat1, qtdColMat2]) INTO matFinal;
        IF qtdColMat1 != qtdLinMat2 THEN
            RAISE EXCEPTION 'Quantidade de colunas da Matriz1 diferente da quantidade de linhas da Matriz2';
        END IF;
        FOR i IN 1..qtdLinMat1 LOOP
            FOR j IN 1..qtdColMat2 LOOP
                FOR k IN 1..qtdLinMat2 LOOP
                    matFinal[i][j] := matFinal[i][j] + matriz1[i][k] * matriz2[k][j];
                END LOOP;
            END LOOP;
        END LOOP;
        RETURN matFinal;
    END;
$$
    LANGUAGE PLPGSQL;


SELECT * FROM produto('{{1,2},{4,5},{9,10}}', '{{2,3,4},{3,4,5}}');

-- FIM QUESTÃO 1

-- QUESTÃO 2

CREATE OR REPLACE FUNCTION transposta (mat float[][])
    RETURNS float[][]
    AS $$
    DECLARE
        qtdLin integer;
        qtdCol integer;
        transposta float[][];
    BEGIN
        SELECT array_length(mat, 1) INTO qtdLin;
        SELECT array_length(mat, 2) INTO qtdCol;
        SELECT array_fill(0,ARRAY[qtdCol,qtdLin]) INTO transposta;
        FOR i IN 1.. qtdCol LOOP
                FOR j IN 1..qtdLin LOOP
                    transposta[i][j] = mat[j][i];
                END LOOP;
        END LOOP;
        RETURN transposta;
    END;
$$
    LANGUAGE PLPGSQL;

SELECT * from transposta(ARRAY[[1,2],[3,4],[5,6]]);

-- FIM QUESTÃO 2

-- QUESTÃO 3

CREATE OR REPLACE FUNCTION resolver(m1 float[][], m2 float[][]) returns float[]
    AS $$
    DECLARE
        x1 float;
        x2 float;
        resultadoFinal float[];
    BEGIN
        x1 = (((m2[1][1] * m1[2][2]) - (m2[2][1] * m1[1][2])) /
             ((m1[1][1] * m1[2][2]) - (m1[2][1] * m1[2][1])));
        x2 = (((m2[2][1] * m1[1][1]) - (m2[1][1] * m1[2][1])) /
             ((m1[1][1] * m1[2][2]) - (m1[2][1] * m1[2][1])));
        resultadoFinal := array_append(resultadoFinal, x1);
        resultadoFinal := array_append(resultadoFinal, x2);
        RETURN resultadoFinal;
    END;
$$
    LANGUAGE PLPGSQL;

SELECT * FROM resolver('{{5, 3}, {3, -5}}', '{{7}, {-23}}');

-- FIM QUESTÃO 3

-- QUESTÃO 4

CREATE OR REPLACE FUNCTION projecao(p_produto int, p_ano_mes int) returns float
    AS $$
    DECLARE
        projecao_ano_mes float;
        x float[][];
        x_trans float[][];
        r float[][];
        x_trans_mult_r float[][];
        x_trans_mult_x float[][];
        mat_x1x2 float[];
    BEGIN
        DROP TABLE IF EXISTS t1;
        CREATE temp table t1 AS SELECT ano_mes, SUM(valor) AS valor FROM venda WHERE produto = p_produto GROUP BY ano_mes;

        DROP TABLE IF EXISTS Refa;
        CREATE temp table Refa AS WITH RECURSIVE Refa(ano_mes, seq) AS (
            SELECT min(ano_mes), 0 FROM venda WHERE produto = p_produto
            UNION
            SELECT
            case when (ano_Mes)%100=12 then ano_mes+89
            else ano_mes+1 end,
            seq+1
            FROM Refa WHERE ano_mes < p_ano_mes)
            SELECT * FROM Refa;

        SELECT ARRAY_AGG(ARRAY[seq,c2]) INTO x FROM (SELECT seq,c2 FROM (SELECT ano_mes, 1 AS c2 FROM t1) AS tab1 NATURAL JOIN Refa) AS tab2;

        SELECT transposta(x) INTO x_trans;

        SELECT ARRAY_AGG(ARRAY[valor]) INTO r FROM t1;

        SELECT produto(x_trans,x) INTO x_trans_mult_x;

        SELECT produto(x_trans, r) INTO x_trans_mult_r;

        SELECT resolver(x_trans_mult_x, x_trans_mult_r) INTO mat_x1x2;

        SELECT seq INTO projecao_ano_mes FROM Refa WHERE ano_mes = p_ano_mes;

        RETURN (projecao_ano_mes * mat_x1x2[1]) + mat_x1x2[2];
    END;
$$
    LANGUAGE PLPGSQL;

SELECT * FROM projecao(10,202007);

-- FIM QUESTÃO 4