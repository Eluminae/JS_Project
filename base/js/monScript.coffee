
$.ajax
  'global': false
  'url': 'http://www.francelink.net/datas.json'
  'dataType': "json"
  'success': (data) ->

    triDate = (listeInitiale) ->
      listeFinale = []

      for liste in listeInitiale

        if listeFinale.length == 0
          # si c'est le premier element
          listeFinale.push liste
        else
          ajoute = false
          for i in [0..listeFinale.length-1]
            # on teste si la valeure vin s'inscruster avant celle qu'on observe
            mois1 = parseInt listeFinale[i].substring(0,2)
            annee1 = parseInt listeFinale[i].substring(3,5)

            moisAjoute = parseInt liste.substring(0,2)
            anneeAjoute = parseInt liste.substring(3,5)

            if anneeAjoute < annee1
              listeFinale.splice i,0,liste
              ajoute = true
              break
            else if anneeAjoute == annee1 && moisAjoute <= mois1
              listeFinale.splice i,0,liste
              ajoute = true
              break
          # si rien n'a ete ajoute, c'est qu'on es arrive au bout de la liste
          if !ajoute
            listeFinale.push liste


      return listeFinale


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

    debug= false

    listeBilanInitiaux = {}

    sommeFacturationParMois = {}

    nbClientFactureParMois = {}

    for bilan in data.bilans
      if bilan.bilan.field_bilan_initial == "1"
        listeBilanInitiaux[bilan.bilan.title_1]= bilan.bilan

    listeDateNonTrie = []
    listeSommeFacturationTrie = []
    listeNbFacturationTrie = []

    analyseJson = () ->
      for bilan in data.bilans
        if bilan.bilan.field_bilan_initial != "1"
          bilan=bilan.bilan
          ceQuilDevraitPayer = 0

          # on vas aller tester tous les mots clefs
          # on ne travaille qu'avec les mots clefs trouvés

          # pour identifier le mot clef

          listeKeyword = JSON.parse(bilan.field_bilan).keyWords
          parsedInitialBilan = JSON.parse(listeBilanInitiaux[bilan.title_1].field_bilan)
          #for keyword in listeKeyword
          for i in [0..listeKeyword.length-1]

            if listeKeyword[i].found == 1

              listeKeywordInitiaux = JSON.parse(listeBilanInitiaux[bilan.title_1].field_bilan);
              listeKeywordInitiaux = listeKeywordInitiaux.keyWords[i];

              # pour tester qu'on ne tombe pas sur un mot clef qui n'etait pas dans le bilan initial
              if listeKeywordInitiaux
                bestPosAct = bestPosition(listeKeyword[i].positions)

                fieldFactuPlace = 0
                if bestPosAct >0 && bestPosAct <= 10
                  fieldFactuPlace = bilan['field_factu_place_'+bestPosAct]

                # si on es pas dans les 10 premiers, pas la peine de se tracasser
                if fieldFactuPlace
                  if listeKeywordInitiaux.found == 0
                    # ici on es forcement au dessus parce qu'on es referencé alors qu'avant non
                    console.log "forcement au dessus" if debug
                    ceQuilDevraitPayer += (fieldFactuPlace*bilan.field_coef_factu_inf)
                  else
                    bestPosInit = bestPosition(parsedInitialBilan.keyWords[i].positions);

                    # si on s'est amélioré
                    if bestPosInit > bestPosAct
                      console.log "au dessus" if debug
                      ceQuilDevraitPayer += (fieldFactuPlace*bilan.field_coef_factu_inf)


                    # si on es egal
                    else if bestPosInit == bestPosAct
                      if bestPosInit == 1
                        console.log "on reste premier" if debug
                        ceQuilDevraitPayer += (fieldFactuPlace*bilan.field_coef_factu_first_iso)
                      else
                        console.log "egal normal" if debug
                        ceQuilDevraitPayer += (fieldFactuPlace*bilan.field_coef_factu_iso)

        console.log "il devrait payer : "+ceQuilDevraitPayer if debug
        if ceQuilDevraitPayer > bilan.field_plafond_facturation
          console.log "or c'est supérieur à " + bilan.field_plafond_facturation if debug
          ceQuilDevraitPayer = parseFloat(bilan.field_plafond_facturation)
        console.log "" if debug


        if bilan.created
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







    rf.StandaloneDashboard (db) ->
      chart = new ChartComponent "sales"
      chart.setCaption "Resultat des facturations par mois"
      chart.setYAxis "Somme des bilans", {numberHumanize: true}
      chart.addYAxis("quantity", "Quantity", []);
      chart.lock()

      analyseJson()

      Object.keys(sommeFacturationParMois).forEach (key) ->
        listeDateNonTrie.push(key)

      listeDateTrie = triDate listeDateNonTrie

      chart.setLabels listeDateTrie

      for key in listeDateTrie
        listeSommeFacturationTrie.push sommeFacturationParMois[key]

      for key in listeDateTrie
        listeNbFacturationTrie.push nbClientFactureParMois[key]

      chart.addSeries "Somme", "Somme", listeSommeFacturationTrie, {seriesDisplayType: "column",numberPrefix: "$"}
      chart.addSeries "nb_client", "Nombre de client", listeNbFacturationTrie, {seriesDisplayType: "line", "yAxis": "quantity"}
      chart.unlock()

      db.addComponent chart