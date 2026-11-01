-- Troca os nomes de demonstração pelas promotoras reais
update promotoras set nome='PrimeCred' where nome='Alfa Promotora';
update promotoras set nome='AC Consignado' where nome='Norte Crédito';
update promotoras set nome='Nossa Agência' where nome='Litoral Consig';
update promotoras set nome='M&C Cred' where nome='Sertão Correspondente';

-- Confira o resultado
select id, nome from promotoras order by id;
