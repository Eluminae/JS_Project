
$.ajax
  'async': true
  'global': false
  'url': 'datas.json'
  'dataType': "json"
  'success': (data) ->



    bestPosition = (positions) ->
      bestPos = null

      i=0
      while bestPos == null && i < positions.length
        bestPos = positions[i].position
        i++


      if bestPos
        for position in positions
          bestPos = position.position if position.position < bestPos
        bestPos
      else
        -1

    determineFieldFactuPlace = (position, bilan) ->
      switch position
        when 1 then bilan.field_factu_place_1
        when 2 then bilan.field_factu_place_2
        when 3 then bilan.field_factu_place_3
        when 4 then bilan.field_factu_place_4
        when 5 then bilan.field_factu_place_5
        when 6 then bilan.field_factu_place_6
        when 7 then bilan.field_factu_place_7
        when 8 then bilan.field_factu_place_8
        when 9 then bilan.field_factu_place_9
        when 10 then bilan.field_factu_place_10
        else 0


    debug= false

    listeBilanInitiaux = {}

    sommeFacturationParMois = {}

    nbClientFactureParMois = {}

    for bilan in data.bilans
      if bilan.bilan.field_bilan_initial == "1"
        listeBilanInitiaux[bilan.bilan.title_1]= bilan.bilan



    for bilan in data.bilans
      if bilan.bilan.field_bilan_initial != "1"
        bilan=bilan.bilan
        ceQuilDevraitPayer = 0

        # on vas aller tester tous les mots clefs
        # on ne travaille qu'avec les mots clefs trouvés

        # pour identifier le mot clef
        i=0
        listeKeyword = JSON.parse(bilan.field_bilan).keyWords
        parsedInitialBilan = JSON.parse(listeBilanInitiaux[bilan.title_1].field_bilan)
        for keyword in listeKeyword
          if keyword.found == 1

            listeKeywordInitiaux = JSON.parse(listeBilanInitiaux[bilan.title_1].field_bilan);
            listeKeywordInitiaux = listeKeywordInitiaux.keyWords[i];


            bestPosAct = bestPosition(keyword.positions)

            fieldFactuPlace = determineFieldFactuPlace(bestPosAct, bilan)

            if listeKeywordInitiaux.found == 0
              if bestPosAct != -1
                # ici on es forcement au dessus parce qu'on es referencé alors qu'avant non
                console.log "forcement au dessus" if debug
                ceQuilDevraitPayer += fieldFactuPlace*bilan.field_coef_factu_inf
              else
                #ici on es des gros looser. pas trouvé à l'init, pas trouvé apres le travail de referencement
            else
              bestPosInit = bestPosition(parsedInitialBilan.keyWords[i].positions);

              # si on s'est amélioré
              if bestPosInit > bestPosAct
                console.log "au dessus" if debug
                ceQuilDevraitPayer += fieldFactuPlace*bilan.field_coef_factu_inf


              # si on es egal
              else if bestPosInit == bestPosAct
                if bestPosInit == 1
                  console.log "on reste premier" if debug
                  ceQuilDevraitPayer += fieldFactuPlace*bilan.field_coef_factu_first_iso
                else
                  console.log "egal normal" if debug
                  ceQuilDevraitPayer += fieldFactuPlace*bilan.field_coef_factu_iso
            i++
        console.log "il devrait payer : "+ceQuilDevraitPayer if debug

        if ceQuilDevraitPayer > bilan.field_plafond_facturation
          console.log "or c'est supérieur à " + bilan.field_plafond_facturation if debug
          ceQuilDevraitPayer = parseFloat(bilan.field_plafond_facturation)
        console.log "" if debug

        if !sommeFacturationParMois[bilan.created]
          sommeFacturationParMois[bilan.created] = 0
        if !nbClientFactureParMois[bilan.created]
          nbClientFactureParMois[bilan.created] = 0

        sommeFacturationParMois[bilan.created] += ceQuilDevraitPayer
        nbClientFactureParMois[bilan.created] += 1

    console.log "somme facturé" if debug
    console.log sommeFacturationParMois if debug
    console.log "par x client" if debug
    console.log nbClientFactureParMois if debug

    console.log "Sommes des facturations par mois"
    Object.keys(sommeFacturationParMois).forEach (key) ->
      console.log key, sommeFacturationParMois[key]

    console.log "Sommes des clients facturés par mois"
    Object.keys(nbClientFactureParMois).forEach (key) ->
      console.log key, nbClientFactureParMois[key]

    rf.StandaloneDashboard (db) ->
      chart = new ChartComponent "sales"
      chart.setDimensions 8,6
      chart.setCaption "sales - 2013 vs 2012"
      chart.setLabels ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "July", "Aug", "Sept", "Oct", "Nov", "Dec"]
      chart.addSeries "sales2013", "2013", [22400, 24800, 21800, 21800, 24600, 27600, 26800, 27700, 23700, 25900, 26800, 24800]
      chart.addSeries "sales2012", "2012", [10000, 11500, 12500, 15000, 16000, 17600, 18800, 19700, 21700, 21900, 22900, 20800], {seriesDisplayType: "line"}
      chart.setYAxis "Sales", {numberPrefix: "$", numberHumanize: true}
      db.addComponent chart