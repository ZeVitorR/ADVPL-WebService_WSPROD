#include "totvs.ch"
#include "restful.ch"
#include "topconn.ch"

WSRESTFUL WSPROD DESCRIPTION "WebService para consultar os dados de um cliente e seu lote."

    WSDATA codcliente as STRING
    WSDATA prinome    as STRING
    WSDATA sobrenome  as STRING
    WSDATA codproduto as STRING
    

    WSMETHOD GET PRODUTO; 
    DESCRIPTION "Retorna informacoes do lote do cliente."; 
    WSSYNTAX "/WSPROD/PRODUTO";
    PATH "/PRODUTO"

    WSMETHOD GET NOME; 
    DESCRIPTION "Retorna informacoes do cliente."; 
    WSSYNTAX "/WSPROD/NOME";
    PATH "/NOME"

    WSMETHOD GET PROD; 
    DESCRIPTION "Retorna informacoes do lote atual do cliente."; 
    WSSYNTAX "/WSPROD/PROD";
    PATH "/PROD"

    WSMETHOD GET VERIFICA; 
    DESCRIPTION "Retorna a verificação se o contrato foi ou não registrado."; 
    WSSYNTAX "/WSPROD/VERIFICA";
    PATH "/VERIFICA"
    
END WSRESTFUL

WSMETHOD GET PRODUTO WSRECEIVE codcliente WSSERVICE WSPROD
    // Variaveis
    Local  cCodCliente   := iif(valtype(self:codcliente)=="U", "", self:codcliente)
    Local  oProd  := JSonObject():New()
    Local nCount := 1
    Local aList  := {}
    Local cAlias := GetNextAlias()
    Local cAliasC := GetNextAlias()
    // Validando o tamanho do código 
    if len(cCodCliente) != 6 
        SetRestFault(400, EncodeUTF8("O código inserido não possui os 6 caracteres do código do cliente. Verifique-o e preencha novamente"))
        return .F.
    endif
    //Fazendo a consulta se tem o código do cliente inserido
    BEGINSQL ALIAS cAliasC
        SELECT SA1.A1_COD
        FROM %table:SA1% SA1
        WHERE SA1.A1_COD = %exp:cCodCliente%
    ENDSQL
    //Validando se cAliasC está vazio cas estiver vai retornar um erro
    if ((cAliasC)->(EOF()))
        SetRestFault(400, EncodeUTF8("Cliente não localizado, verifique o código inserido e preencha novamente."))
        return .F.
    endif
    //Fazendo a consulta do produto do cliente
    BEGINSQL ALIAS cAlias
        SELECT DISTINCT SE1.E1_CLIENTE, SA1.A1_NOME, SA1.A1_PFISICA, SA1.A1_ORGEMIS, SA1.A1_CGC, SA1.A1_DDD, SA1.A1_TEL,
				SA1.A1_DDDCEL, SA1.A1_CELULAR, SA1.A1_CEP, SA1.A1_BAIRRO, SA1.A1_MUN, SA1.A1_EST, SA1.A1_END,
				SE1.E1_FILIAL, SYS_COMPANY.M0_NOMECOM, SYS_COMPANY.M0_CGC, SE1.E1_PRODUTO, SB1.B1_DESC,
               (SELECT DISTINCT TOP 1 B1_DESC FROM SB1020 WHERE B1_COD = SB1.B1_LOTEAM) 'EMPREENDIMENTO', 
               SB1.B1_NUMLOT, SB1.B1_QUADRA,(SELECT DISTINCT B1_CADMUN FROM SB1020 
											 WHERE B1_FILIAL = SE1.E1_FILIAL AND B1_CADMUN <> '' 
											 AND B1_COD = SB1.B1_COD) 'B1_CADMUN'
        FROM SE1020 SE1, SA1020 SA1, SB1020 SB1, SYS_COMPANY
        WHERE SA1.A1_COD = SE1.E1_CLIENTE 
              AND SE1.E1_FILIAL = SYS_COMPANY.M0_CODFIL
              AND SE1.E1_PRODUTO = SB1.B1_COD
              AND SE1.E1_CLIENTE = %exp:cCodCliente%
              AND SB1.B1_QUADRA <> ''
    ENDSQL
    //contando quantos registro vieram e armazeno na variavel nRegistros
    Count to nRegistros    
    (cAlias)->(dbGoTop())     
    While !((cAlias)->(EOF()))
        aAdd(aList,JSonObject():New())
            aList[nCount][ 'CodCliente' ]     := AllTrim((cAlias)->E1_CLIENTE)
            aList[nCount][ 'NomeCliente' ]    := AllTrim((cAlias)->A1_NOME)
            aList[nCount][ 'RgCliente' ]      := AllTrim((cAlias)->A1_PFISICA)
            aList[nCount][ 'OrgaoExpd' ]      := AllTrim((cAlias)->A1_ORGEMIS)
            aList[nCount][ 'CpfCliente' ]     := AllTrim((cAlias)->A1_CGC)
            aList[nCount][ 'TelCliente' ]     := "("+AllTrim((cAlias)->A1_DDD)+") "+ AllTrim((cAlias)->A1_TEL)
            aList[nCount][ 'CelCliente' ]     := "("+AllTrim((cAlias)->A1_DDDCEL)+") "+ AllTrim((cAlias)->A1_CELULAR)
            aList[nCount][ 'Cep' ]            := AllTrim((cAlias)->A1_CEP)
            aList[nCount][ 'Cidade' ]         := AllTrim((cAlias)->A1_MUN)
            aList[nCount][ 'Estado' ]         := AllTrim((cAlias)->A1_EST)
            aList[nCount][ 'Endereco' ]       := AllTrim((cAlias)->A1_END)
            aList[nCount][ 'Bairro' ]         := AllTrim((cAlias)->A1_BAIRRO)
            aList[nCount][ 'CodFilial' ]      := AllTrim((cAlias)->E1_FILIAL)
            aList[nCount][ 'RazaoFilial' ]    := AllTrim((cAlias)->M0_NOMECOM)
            aList[nCount][ 'CnpjFilial' ]     := AllTrim((cAlias)->M0_CGC)
            aList[nCount][ 'CodProd' ]        := AllTrim((cAlias)->E1_PRODUTO)
            aList[nCount][ 'Produto' ]        := AllTrim((cAlias)->B1_DESC)
            aList[nCount][ 'Empreendimento' ] := AllTrim((cAlias)->EMPREENDIMENTO)
            aList[nCount][ 'Lote' ]           := AllTrim(CVALTOCHAR((cAlias)->B1_NUMLOT))
            aList[nCount][ 'Quadra' ]         := AllTrim((cAlias)->B1_QUADRA)
            aList[nCount][ 'CadMun' ]         := AllTrim((cAlias)->B1_CADMUN)            
        nCount++
        (cAlias)->(DBSKIP())
    end
    (cAlias)->(DBCLOSEAREA())

    oProd["ProdutoCliente"] := aList
    
    // Json to String
    cResponse := oProd:toJson()

    // Define tipo de retorno.
    self:SetContentType('application/json')

    // Define resposta.
    self:SetResponse( EncodeUTF8( cResponse ) )

return .T.

WSMETHOD GET NOME WSRECEIVE prinome, sobrenome WSSERVICE WSPROD

    // Variaveis.
    local   cPriNome  := self:prinome
    local   cSobre    := self:sobrenome
    local   oCliente  := JSonObject():New()
    local   cResponse := ""
    local   nCount    := 1
    local   cAlias    := GetNextAlias()
    Local   aList     := {}
    Local   cquery    := ""


    cquery := " SELECT A1_COD, A1_NOME "
    cquery += " FROM "  + RetSqlTab("SA1")
    cquery += " WHERE D_E_L_E_T_ = '' "
    cquery += "       AND A1_NOME LIKE '%"+cPriNome+"%' "
    cquery += "       AND A1_NOME LIKE '%"+cSobre+"%' "
    cquery += " ORDER BY A1_NOME"

    TCQUERY cQuery New Alias (cALIAS)    

    // Posiciona no topo.
    (cAlias)->(DbGoTop())

    While !((cAlias)->(EOF()))
        aAdd(aList,JSonObject():New())
            aList[nCount]['CodCliente']        := AllTrim((cAlias)->A1_COD)
            aList[nCount]['NomeCliente']       := AllTrim((cAlias)->A1_NOME) 
            
            
        nCount++

        (cAlias)->(DBSKIP())
    end   

    (cAlias)->(DBCLOSEAREA())

    oCliente["Cliente"] := aList

    // Json to String
    cResponse := oCliente:toJson()

    // Define tipo de retorno.
    self:SetContentType('application/json')

    // Define resposta.
    self:SetResponse( EncodeUTF8( cResponse ) )

return .T.

WSMETHOD GET PROD WSRECEIVE codcliente WSSERVICE WSPROD

    // Variaveis
    Local  cCodCliente   := iif(valtype(self:codcliente)=="U", "", self:codcliente)
    Local  oProd  := JSonObject():New()
    Local nCount := 1
    Local aList  := {}
    Local cAlias := GetNextAlias()
    Local cAliasC := GetNextAlias()

    // Validando o tamanho do código 
    if len(cCodCliente) != 6 
        SetRestFault(400, EncodeUTF8("O código inserido não possui os 6 caracteres do código do cliente. Verifique-o e preencha novamente"))
        return .F.
    endif

    //Fazendo a consulta se tem o código do cliente inserido
    BEGINSQL ALIAS cAliasC
        SELECT SA1.A1_COD
        FROM %table:SA1% SA1
        WHERE SA1.A1_COD = %exp:cCodCliente%
    ENDSQL

    //Validando se cAliasC está vazio, SE estiver vai retornar um erro
    if ((cAliasC)->(EOF()))
        SetRestFault(400, EncodeUTF8("Cliente não localizado, verifique o código inserido e preencha novamente."))
        return .F.
    endif

    //Fazendo a consulta do produto do cliente
    BEGINSQL ALIAS cAlias
        SELECT DISTINCT
            //DADOS DO CLIENTE:
                SA1.A1_NOME,SA1.A1_PROFIS,SA1.A1_CGC,SA1.A1_PFISICA,SA1.A1_ORGEMIS,SA1.A1_EMAIL,SA1.A1_DDD, SA1.A1_TEL, SA1.A1_DDDCEL,SA1.A1_CELULAR,   
                //ENDEREÇO:
                SA1.A1_MUN, SA1.A1_EST, SA1.A1_CEP, SA1.A1_END, SA1.A1_BAIRRO,
                //ENDEREÇO COMERCIAL:
                SA1.A1_ENDCOM, SA1.A1_BAIRCOM, SA1.A1_ESTCOM, SA1.A1_MUNCOM, SA1.A1_CEPCOM,
                //ENDEREÇO DE COBRANÇA:
			    SA1.A1_ENDCO, SA1.A1_BAICO, SA1.A1_CIDCO, SA1.A1_CEPCO, SA1.A1_UFCO,
            //DADOS DO PRODUTO:
                ZZZ_FILIAL,SB1.B1_COD,SM0.M0_NOMECOM,SM0.M0_CGC, (SELECT DISTINCT TOP 1 B1_DESC FROM SB1020 WHERE B1_COD = SB1.B1_LOTEAM) 'EMPREENDIMENTO',
                SB1.B1_DESC, SB1.B1_NUMLOT, SB1.B1_QUADRA, (SELECT DISTINCT B1_CADMUN FROM SB1020 
                                                            WHERE B1_FILIAL = ZZZ_FILIAL AND B1_CADMUN <> '' 
                                                            AND B1_COD = SB1.B1_COD) 'B1_CADMUN' 	
        FROM
            %table:ZZZ% ZZ0
        INNER JOIN
            %table:SA1% SA1 ON ZZ0.ZZZ_CLIORI = SA1.A1_COD
        INNER JOIN
            %table:SB1% SB1 ON ZZ0.ZZZ_CODPRO = SB1.B1_COD
        INNER JOIN
            SYS_COMPANY SM0 ON ZZ0.ZZZ_FILIAL = SM0.M0_CODFIL
        WHERE
            ZZ0.ZZZ_PROATU = 'S'
            AND ZZ0.%notDel%
            AND SA1.%notDel%
            AND SA1.A1_COD = %exp:cCodCliente%
        ORDER BY
            EMPREENDIMENTO,SB1.B1_DESC
    ENDSQL

    //contando quantos registro vieram e armazeno na variavel nRegistros
    Count to nRegistros

    
    (cAlias)->(dbGoTop())     
    While !((cAlias)->(EOF()))
        aAdd(aList,JSonObject():New())
            aList[nCount][ 'NomeCliente' ]    := AllTrim((cAlias)->A1_NOME)
            aList[nCount][ 'Profissao' ]      := AllTrim((cAlias)->A1_PROFIS)
            aList[nCount][ 'RgCliente' ]      := AllTrim((cAlias)->A1_PFISICA)
            aList[nCount][ 'OrgaoExpd' ]      := AllTrim((cAlias)->A1_ORGEMIS)
            aList[nCount][ 'CpfCliente' ]     := AllTrim((cAlias)->A1_CGC)
            aList[nCount][ 'email' ]          := AllTrim((cAlias)->A1_EMAIL)
            aList[nCount][ 'TelCliente' ]     := "("+AllTrim((cAlias)->A1_DDD)+") "+ AllTrim((cAlias)->A1_TEL)
            aList[nCount][ 'CelCliente' ]     := "("+AllTrim((cAlias)->A1_DDDCEL)+") "+ AllTrim((cAlias)->A1_CELULAR)
            aList[nCount][ 'Cep' ]            := AllTrim((cAlias)->A1_CEP)
            aList[nCount][ 'Cidade' ]         := AllTrim((cAlias)->A1_MUN)
            aList[nCount][ 'Estado' ]         := AllTrim((cAlias)->A1_EST)
            aList[nCount][ 'Endereco' ]       := AllTrim((cAlias)->A1_END)
            aList[nCount][ 'Bairro' ]         := AllTrim((cAlias)->A1_BAIRRO)

            aList[nCount][ 'CepCOM' ]            := AllTrim((cAlias)->A1_CEPCOM)
            aList[nCount][ 'CidadeCOM' ]         := AllTrim((cAlias)->A1_MUNCOM)
            aList[nCount][ 'EstadoCOM' ]         := AllTrim((cAlias)->A1_ESTCOM)
            aList[nCount][ 'EnderecoCOM' ]       := AllTrim((cAlias)->A1_ENDCOM)
            aList[nCount][ 'BairroCOM' ]         := AllTrim((cAlias)->A1_BAIRCOM)

            aList[nCount][ 'CepCOB' ]            := AllTrim((cAlias)->A1_CEPCO)
            aList[nCount][ 'CidadeCOB' ]         := AllTrim((cAlias)->A1_CIDCO)
            aList[nCount][ 'EstadoCOB' ]         := AllTrim((cAlias)->A1_UFCO)
            aList[nCount][ 'EnderecoCOB' ]       := AllTrim((cAlias)->A1_ENDCO)
            aList[nCount][ 'BairroCOB' ]         := AllTrim((cAlias)->A1_BAICO)

            aList[nCount][ 'CodFilial' ]      := AllTrim((cAlias)->ZZZ_FILIAL)
            aList[nCount][ 'RazaoFilial' ]    := AllTrim((cAlias)->M0_NOMECOM)
            aList[nCount][ 'CnpjFilial' ]     := AllTrim((cAlias)->M0_CGC)
            aList[nCount][ 'Produto' ]        := AllTrim((cAlias)->B1_DESC)
            aList[nCount][ 'CodProd' ]        := AllTrim((cAlias)->B1_COD)
            aList[nCount][ 'Empreendimento' ] := AllTrim((cAlias)->EMPREENDIMENTO)
            aList[nCount][ 'Lote' ]           := AllTrim(CVALTOCHAR((cAlias)->B1_NUMLOT))
            aList[nCount][ 'Quadra' ]         := AllTrim((cAlias)->B1_QUADRA)
            aList[nCount][ 'CadMun' ]         := AllTrim((cAlias)->B1_CADMUN)            
        nCount++
        (cAlias)->(DBSKIP())
    end
    (cAlias)->(DBCLOSEAREA())

    oProd["Produto"] := aList
    
    // Json to String
    cResponse := oProd:toJson()

    // Define tipo de retorno.
    self:SetContentType('application/json')

    // Define resposta.
    self:SetResponse( EncodeUTF8( cResponse ) )

return .T.

WSMETHOD GET VERIFICA WSRECEIVE codcliente, codproduto WSSERVICE WSPROD

    // Variaveis.
    local   cCodCli   := self:codcliente
    local   cCodPro   := self:codproduto
    local   oCliente  := JSonObject():New()
    local   cResponse := ""
    local   nCount    := 1
    local   cAlias    := GetNextAlias()
    Local   aList     := {}

    BEGINSQL ALIAS cAlias
        SELECT * FROM ZZC020 WHERE ZZC_CLIENT = %exp:cCodCli% AND ZZC_PRODUT = %exp:cCodPro% AND ZZC_REGIST <> ''
    ENDSQL
    

    // Posiciona no topo.
    (cAlias)->(DbGoTop())

    IF !((cAlias)->(EOF()))
        aAdd(aList,JSonObject():New())
            aList[nCount]['CodCli']        := AllTrim((cAlias)->ZZC_CLIENT)
            aList[nCount]['CodPro']        := AllTrim((cAlias)->ZZC_PRODUT)
            aList[nCount]['Regist']        := SUBSTR( (cAlias)->ZZC_REGIST,7,2)+'/'+SUBSTR((cAlias)->ZZC_REGIST,5,2)+'/'+left((cAlias)->ZZC_REGIST,4)
            aList[nCount]['Veri']          := 0       
    else
        aAdd(aList,JSonObject():New())
        aList[nCount]['Veri']              := 1   
    end   

    (cAlias)->(DBCLOSEAREA())

    oCliente["Cliente"] := aList

    // Json to String
    cResponse := oCliente:toJson()

    // Define tipo de retorno.
    self:SetContentType('application/json')

    // Define resposta.
    self:SetResponse( EncodeUTF8( cResponse ) )

return .T.
