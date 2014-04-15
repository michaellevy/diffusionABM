
globals [
        number_of_regions      ;; main outcome variable
        regions_list           ;; list of region identifyers
        
        x_of_active            ;; these are the coordinates of the selected agent
        y_of_active
;        overlap                ;; overlap among the features of the selected agent and its neighbour. It corresponds to the porbability of trait adoption
        cumm-dist              ;; replaces overlap -- distance between two focal agents over all traits
        closeness              ;; inverse average distance -- how close are two focal agents over all traits
        chosen-feature         ;; feature selected to be copied by the selected agent
        new-trait              ;; trait (feature value) adopted by the selected agent from its neighbour
        
        my_neighbors           ;; these are auxiliar variables used along the code
        found
        loop-step            
        dist-to-move       
        
        ]
patches-own 
        [                      ;; define here the characteristics of the agents (because agents do not move, these are patches)
        feature                ;; ML: [0,1] floatlist of cultural features of each agent (patch)
        color1                 ;; this is the color of the first feature (the only one we present at the interface)
        region_id              ;; this is the 'opinion region' to wich the agent belongs
        ]


to setup
  clear-all   
   ask patches                 ;; the following commands are executed by all the agents (in a sequential way) when 'setup' botton is pressed
      [                        ;; basically, they initialized the system
      set feature (list random-float 1 random-float 1 random-float 1 random-float 1 random-float 1 random-float 1 random-float 1 random-float 1 random-float 1 random-float 1 random-float 1 random-float 1 random-float 1 random-float 1 random-float 1 random-float 1 random-float 1 random-float 1 random-float 1 random-float 1)
      if report_CC = true [print feature]
      recolor-patch
      ]
;      make-regions-list        ;; ML: Regions, as defined by Axelrod, don't make sense here, because traits are continuous and regions lean on them being, at times and places, identical.
      reset-ticks
end         ;;to setup


to go
    ;; the following commands are executed iteratively in an infinite loop while 'run' botton is pressed

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;;;;;; Mutation (not Axelrod)  ;;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   if random-float (1.0) < mutation_rate [ ask patch random (max-pxcor + 1) random (max-pycor + 1) [set feature replace-item random (number_of_Features) feature random (number_of_traits)]] 
   


   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;1st: choose agent to be updated  ;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   set x_of_active random (max-pxcor + 1)  
   set y_of_active random (max-pycor + 1)   
   if report_CC = true [print (word  "chosen agent is "(list x_of_active y_of_active)) ]  ; this message is shown only if 'report_CC' in the interface is ON

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;2nd: select interaction partner  ;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
   ask patch x_of_active y_of_active
            [
            ifelse range_of_interaction = 3 [set my_neighbors other ( patches in-radius 2 )][ifelse range_of_interaction = 2 [set my_neighbors neighbors][set my_neighbors neighbors4]] ;; defines the neighborhood
            ;;ask my_neighbors [set pcolor (green)]
            if report_CC = true [print my_neighbors ]
            let feature_neigh [feature] of one-of my_neighbors                ;; copies the features of the interaction partner to the focal agent 
        ;; Above is the random neighbor selection
            ;;print feature_neigh                         
            
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;3rd: calculate the cultural similarity  ;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            calc-overlap feature_neigh
            if report_CC = true [print feature]
            if report_CC = true [print feature_neigh]
            set cumm-dist cumm-dist / number_of_Features    ;; ML: From cummulative to average distance
            set closeness 1 - cumm-dist                     ;; ML: For prob(interact)
;            if overlap = 0 [set overlap no_overlap_prob]    ;; ML: If selected agents have no overlap, set their probability of interaction to slider no_overlap_prob.
            ;;print overlap
            
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;4th: social influence                   ;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;           
            if (closeness < 1) and ((closeness > random-float 1) or (Random_interaction > (random 100) + 1)) [  ;; Notice that (Random_interaction > (random 100) + 1) correspond to the noise, which is not included in Axelrod's model   
    
              ;;print Random_interaction
              ifelse number_of_Features = 1 
              [
                set chosen-feature 0
              ]
              [
                choose-feature feature_neigh
              ]
              move-feature feature_neigh                      ;; ML: Move's focal agent's value according to neighbor's 

                
;              set new-trait item chosen-feature feature_neigh
;              set feature replace-item chosen-feature feature new-trait

            
;            if report_CC = true [print overlap]              ;; these parameter's values are shown only if 'report_CC' in the interface is ON
            if report_CC = true [print chosen-feature]
            if report_CC = true [print feature]
            if report_CC = true [print feature_neigh]
            
            recolor-patch
            ]

            ] ;;ask patch x_of_active y_of_active

   if number_of_Features = 5                                  ;; ML: Had to brute-force this because couldn't make number_of_Features a variable-length list. It would be great to know how to do that / have that functionality.
   [ if max (list standard-deviation [item 0 feature] of patches standard-deviation [item 1 feature] of patches standard-deviation [item 2 feature] of patches standard-deviation [item 3 feature] of patches standard-deviation [item 4 feature] of patches) < 0.01
        [stop]
   ]
   if number_of_Features = 3
   [ if max (list standard-deviation [item 0 feature] of patches standard-deviation [item 1 feature] of patches standard-deviation [item 2 feature] of patches ) < 0.01
        [stop]
   ]
   if number_of_Features = 1
   [ if standard-deviation [item 0 feature] of patches < 0.01
        [stop]
   ]
   if ticks >= 250000 [stop]
    tick


                  
end      ;;to go


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; Some procedures called from 'go' ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to choose-feature [b]                                             ;; ML: Need to define new method to choose feature to interact on, since the old one (point-dissimilar) used identical values but now we have floats.
  ifelse Choose_feature_method = "Randomly" [                     ;; ML: Chooser on interface screen for these three methods. Randomly just picks random feature.
    set chosen-feature random number_of_Features
    ]
    [
    ifelse Choose_feature_method = "Most-dissimilar"              ;; ML: Find the feature with most distance between two focal agents
    [
      let max-dist 0
      set loop-step 0
    loop [                                                        ;; ML: Loop over the vector of features
      let disti abs (item loop-step feature - item loop-step b)   ;; ML: For each feature, how far apart are the two agents?
      if disti > max-dist                                         ;; ML: If further than any previously found value, store the current feature (loop-step) to chosen-feature and update max found
      [
        set chosen-feature loop-step
        set max-dist disti
      ]        
      set loop-step loop-step + 1
      if loop-step = number_of_Features [stop]
      ]
    ]
    [
      let min-dist 1                                            ;; ML: Method must be "Most-similar"
      set loop-step 0
      loop
      [
        let disti abs (item loop-step feature - item loop-step b)   ;; ML: Same as in "Most-dissimilar", except searching for the minimum value here.
        if disti < min-dist [
          set chosen-feature loop-step 
          set min-dist disti
        ]
        set loop-step loop-step + 1
        if loop-step = number_of_Features [stop]
      ]
    ]
  ]    
end           ;; to chosen-feature


;to point-dissimilar [b]    ;; ML: Replaced by above. determines the feature value to be copied by the selected agent from its neighbour
;  set found false
;  loop [
;    set chosen-feature random number_of_Features
;    if item chosen-feature feature != item chosen-feature b [set found true]
;    if found [stop]
;  ]
;end          ;;to point-dissimilar



to calc-overlap [b]        ;; calculates the similarity
  set loop-step 0
  set cumm-dist 0
  loop [
    ;;print loop-step
    let disti abs (item loop-step feature - item loop-step b)                    ;; ML: Stores distance between two agents on feature loop-step
    set cumm-dist cumm-dist + disti                                              ;; ML: Adds distance on current trait to total distance
    set loop-step loop-step + 1
    if loop-step = number_of_Features [stop]
    ;;print overlap
  ]
end      ;;to calc-overlap


to move-feature [b]                                                              ;; ML: Change selected feature of focal agent based on neighbors value and user-selected rule.
  ifelse feature_move_method = "identical"
  [
    let yours item chosen-feature b
    set feature replace-item chosen-feature feature yours                        ;; ML: Copy neighbor's value for chosen-feature into ego's 
  ]
  [
    let mine item chosen-feature feature 
    let yours item chosen-feature b
    let dist mine - yours                                                        ;; ML: Calculate distance between two agent's values
    ifelse feature_move_method = "midpoint"                                      ;; ML: If midpoint method, halve the distance
      [ set dist-to-move dist * 0.5 ]       
      [ set dist-to-move random-float dist ]                                     ;; ML: If not midpoint, must be random, so pull random number [0,distance). Note: If distance is negative (neighbor's greater), this draws a from (distance,0], so all's well.
    let change-to item chosen-feature feature - dist-to-move                     ;; Calculate new value
    set feature replace-item chosen-feature feature change-to                    ;; ML: Finally, change ego's value.
  ]
end      ;; to move-feature


to recolor-patch
     set pcolor (item 0 feature) * 10
end        ;;to recolor-patch


to make-regions-list   ;; calculates the number of regions
  set regions_list []
  ask patches[
  calc-region-id
  ;;print region_id
  set regions_list fput region_id regions_list
  ]
  ;;print regions_list
  set regions_list remove-duplicates regions_list
  ;;print regions_list
  set number_of_regions length regions_list
  ;;print number_of_regions
  do-plot
end                    ;; to make-regions-list


to calc-region-id      ;; determines the region to which an agent belongs 
    set region_id item 0 feature
    set loop-step 1
    loop[

      set region_id region_id + (10 ^ loop-step)*(item loop-step feature) 
      set loop-step loop-step + 1
      if loop-step = number_of_Features [stop]
    ]  
end                    ;; to calc-region-id



to do-plot            ;; updates the plot
  set-current-plot "Number of Regions"
  plot number_of_regions
end


; This model was developed by Michael Maes (M.Maes@rug.nl) and Sergi Lozano (slozano@ethz.ch)
; Zurich, October 2008


 
@#$#@#$#@
GRAPHICS-WINDOW
232
14
517
320
-1
-1
25.0
1
10
1
1
1
0
0
0
1
0
10
0
10
1
1
1
ticks
30.0

BUTTON
7
13
70
46
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
7
101
179
134
number_of_Features
number_of_Features
1
5
5
2
1
NIL
HORIZONTAL

SLIDER
8
139
180
172
range_of_interaction
range_of_interaction
1
3
2
1
1
NIL
HORIZONTAL

BUTTON
95
13
158
46
run
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
16
633
129
666
report_CC
report_CC
1
1
-1000

SLIDER
8
309
182
342
Random_interaction
Random_interaction
0
100
0
1
1
%
HORIZONTAL

SLIDER
8
267
182
300
mutation_rate
mutation_rate
0.0
0.01
0
0.0005
1
NIL
HORIZONTAL

TEXTBOX
30
78
180
96
Axelrod's parametres
14
0.0
1

TEXTBOX
31
245
181
263
Extension parametres
14
0.0
1

SLIDER
9
353
181
386
no_overlap_prob
no_overlap_prob
0
1
0
.01
1
NIL
HORIZONTAL

CHOOSER
275
357
438
402
Choose_feature_method
Choose_feature_method
"Randomly" "Most-dissimilar" "Most-similar"
2

TEXTBOX
275
568
554
664
Note: This determines how the selected agent's trait changes, given a successful interaction. For the chosen feature, \"identical\" makes agent's value the same as neighbor's; \"midpoint\" moves agent's value halfway toward neighbor's; and \"randomly\" moves agent's value a random distance strictly toward neighbor's, from a uniform distribution
10
0.0
1

CHOOSER
274
523
425
568
feature_move_method
feature_move_method
"identical" "midpoint" "randomly"
2

TEXTBOX
277
404
554
516
Note: This governs the method used to select a feature on which the focal agent and its neighbor interact. The names should be self-explanatory. Importantly, the selected feature is used for the calculation of probability of interaction, and it is that feature that is subsequently made more similar if the interaction is successful. For now, these are bound together, but it would be interesting to separate them in future version of the model.
10
0.0
1

PLOT
40
434
240
584
plot 1
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot standard-deviation [item 0 feature] of patches"
"pen-1" 1.0 0 -7500403 true "" "plot mean [item 0 feature] of patches"
"pen-2" 1.0 0 -955883 true "" "plot standard-deviation [item 1 feature] of patches"
"pen-3" 1.0 0 -1184463 true "" "plot standard-deviation [item 2 feature] of patches"
"pen-4" 1.0 0 -10899396 true "" "plot standard-deviation [item 3 feature] of patches"
"pen-5" 1.0 0 -13791810 true "" "plot standard-deviation [item 4 feature] of patches"

@#$#@#$#@
## WHAT IS IT?

This is Axelrod's model of cultural dissemination. It models a population of actors that hold a number of cultural attributes (called features) and interact with their neighbors. Dynamics are based on two main mechanisms. First, agents tend to chose culturally similar neighbors as interaction partners (homophily). Second, during interaction agents influence each other in a way that they become more similar. The interplay of these mechanisms either leads to cultural homogeneity (all agents are perfectly similar) or the development of culturally distinct regions. The model allows studying to which degree the likelihood of these two outcomes depends on the size of the population, the number of features the agents hold, the number of traits (values) each feature can adopt and the neighborhood size (interaction range). We furthermore implemented cultural mutation and random interaction. 

## HOW IT WORKS

Each patch of the grid represents an agent. Agents hold a number of features. Each feature is a nominal variable that can adopt a certain number of values (called traits). Initially, agents adopt randomly chosen traits.   
During each tick, the computer randomly selects a patch as the focal agent. Then, one of the focal agent's neighbors is selected at random and the cultural overlap between these two agents is computed. The cultural overlap is equal to the percentage of similar features.   
With probability similar to the overlap, the two agents interact. Otherwise, the program continues with the next tick. An interaction consists of selecting at random one of the features on which the two agents differ and changing the focal agent's feature to the interaction partner's trait.  
Note that if the overlap is zero, interaction is not possible and the respective agents refuse to influence each other. 

## HOW TO USE IT

First, you should choose the population size. Use the black arrows in the grid window to manipulate the size of the grid.   
Second, click on SETUP to initialize the population. You can influence, how many features the agents hold by using the 'NUMBER_OF_FEATURES' slider. How many traits each feature can adopt can be changed with the 'NUMBER_OF_TRAITS' slider. Furthermore, you can vary the size of the neighborhood. Here, 1 means that each agent has 4 neighbors. 2 corresponds to 8 neighbors and 3 to 12 neighbors. In the grid, each patch (agent) adopts a color which represents the agent�s trait on the first feature. If two patches adopt the same color, they are similar on the first feature.  

Click on RUN and the simulation starts. You can follow the changes of the first feature in the grid. Furthermore, there is a graph reporting the number of cultural regions in the population. A region is a set of agents that are similar on all features 

We included two crucial extensions of Axelrod's model. First, you can implement cultural mutation, meaning that sometimes the computer changes a randomly chosen feature of a randomly chosen agent to a randomly chosen trait. The probability of such changes can be influenced using the 'MUTATION_RATE' slider. 

Secondly, we allowed for interaction between dissimilar neighbors. In the original model, agents do not interact when the overlap is zero. It has been shown (see references below) that relaxing this assumption changes the outcomes of the model significantly. We implemented that as follows. If two agents that are dissimilar on all features are selected for interaction, then the probability that social influence occurs is similar to the value chosen with the 'RANDOM_INTERACTION' slider.

## THINGS TO NOTICE

Note that the model does not stop 'ticking' when equilibrium is reached. When there are no changes in the grid and the number of regions is stable over a reasonable long time, you should click on the RUN button to stop the process.  

Note furthermore that for the assessment of the number of regions, the model only counts the number of distinct attribute vectors in the population. The program does not check if two sets of agents that hold similar features are connected or not. It could thus happen that you see for instance three regions in the grid but the number of regions is only 2.

You can use the 'REPORT_CC' switch to follow the steps of the simulation and for debugging. Note that this makes the program slower.

## THINGS TO TRY

Vary the population size, the number of features, the number of traits and the range of interactions. Conduct experiments to find out under which conditions the model predicts cultural differences. You will find quite some counter intuitive effects. Axelrod�s paper (see below) provides you with explanations for these effects.

In addition, you could change grid to a torus (a world that looks like a donut) by activating 'World wraps horizontally' and 'World wraps vertically' in the Settings menu. Why do the model's implications change?

Experiment with a very small mutation rate. What happens? Why? Try also high mutation rates. 

Allow for random interaction. To start with, you could run a simulation without random interaction until stable regions have developed and then put the 'RANDOM_INTERACTION' slider to 5% and click on run again. 

## EXTENDING THE MODEL

Many extensions of this model have been proposed (see e.g. references below). One of the most interesting is certainly the inclusion of metric features. Interestingly, it has been shown that this makes the persistence of different cultural regions very unlikely. Try to think of ways to make cultural diversity possible again. 

Incorporate social networks into this model. Currently, agents interact only with their neighbors and all agents (except those at the borders) have the same number of neighbors. Both could be changed.

## NETLOGO FEATURES

Note that the agents (patches) hold several features. We used lists to implement that.  
The model allows varying the size of the neighborhoods. 

## RELATED MODELS

Flache, Andreas, and Michael M�s. 2008. "How to get the timing right? A computational model of how demographic faultlines undermine team performance and how the right timing of contacts can solve the problem." Computational and Mathematical Organization Theory 14:23-51.

Hegselmann, Rainer, and Ulrich Krause. 2002. "Opinion Dynamics and Bounded Confidence Models, Analysis, and Simulation." Journal of Artificial Societies and Social Simulation 5.

## CREDITS AND REFERENCES

This model has been developed by Robert Axelrod. It was implemented by Sergi Lozano (slozano@ethz.ch) and Michael Maes (m.maes@rug.nl).

This is the paper where Axelrod presented the model: 

Axelrod, R. 1997. "The dissemination of culture - A model with local convergence and global polarization." Journal of Conflict Resolution 41:203-226.

Extensions can be found at:

Flache, A., and M. Macy. 2006. "What sustains cultural diversity and what undermines it? Axelrod and beyond." arXiv:physics/0604201v1 [physics.soc-ph].

Flache, A., and M. Macy. 2007. "Local Convergence and Global Diversity: The Robustness of Cultural Homophily." arXiv:physics/0701333v1 [physics.soc-ph].

Klemm, K., V. M. Eguiluz, R. Toral, and M. S. Miguel. 2003a. "Global culture: A noise-induced transition in finite systems." Physical Review E 67:-.

Klemm, K., V. M. Eguiluz, R. Toral, and M. San Miguel. 2003b. "Nonequilibrium transitions in complex networks: A model of social interaction." Physical Review E 67



Copyright 2008 by Sergi Lozano (slozano@ethz.ch) and Michael Maes (m.maes@rug.nl).  All rights reserved.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Features_x_choose_feature_x_feature_move_n20_thresh01_record_only_ticks" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="250005"/>
    <metric>Ticks</metric>
    <enumeratedValueSet variable="feature_move_method">
      <value value="&quot;randomly&quot;"/>
      <value value="&quot;midpoint&quot;"/>
      <value value="&quot;identical&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Choose_feature_method">
      <value value="&quot;Randomly&quot;"/>
      <value value="&quot;Most-dissimilar&quot;"/>
      <value value="&quot;Most-similar&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_of_Features">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no_overlap_prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Random_interaction">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation_rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="report_CC">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range_of_interaction">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="One_feat_varying_how-move" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>standard-deviation [item 0 feature] of patches</metric>
    <metric>mean [item 0 feature] of patches</metric>
    <metric>standard-deviation [item 1 feature] of patches</metric>
    <metric>mean [item 1 feature] of patches</metric>
    <metric>standard-deviation [item 2 feature] of patches</metric>
    <metric>mean [item 2 feature] of patches</metric>
    <metric>standard-deviation [item 3 feature] of patches</metric>
    <metric>mean [item 3 feature] of patches</metric>
    <metric>standard-deviation [item 4 feature] of patches</metric>
    <metric>mean [item 4 feature] of patches</metric>
    <enumeratedValueSet variable="number_of_Features">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feature_move_method">
      <value value="&quot;midpoint&quot;"/>
      <value value="&quot;identical&quot;"/>
      <value value="&quot;randomly&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no_overlap_prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Random_interaction">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation_rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="report_CC">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Choose_feature_method">
      <value value="&quot;Most-similar&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range_of_interaction">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="One_feat_varying_how-move_tracking_values" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>standard-deviation [item 0 feature] of patches</metric>
    <metric>[item 0 feature] of patch 0 0</metric>
    <metric>[item 0 feature] of patch 0 1</metric>
    <metric>[item 0 feature] of patch 0 2</metric>
    <metric>[item 0 feature] of patch 0 3</metric>
    <metric>[item 0 feature] of patch 0 4</metric>
    <metric>[item 0 feature] of patch 0 5</metric>
    <metric>[item 0 feature] of patch 0 6</metric>
    <metric>[item 0 feature] of patch 0 7</metric>
    <metric>[item 0 feature] of patch 0 8</metric>
    <metric>[item 0 feature] of patch 0 9</metric>
    <metric>[item 0 feature] of patch 1 0</metric>
    <metric>[item 0 feature] of patch 1 1</metric>
    <metric>[item 0 feature] of patch 1 2</metric>
    <metric>[item 0 feature] of patch 1 3</metric>
    <metric>[item 0 feature] of patch 1 4</metric>
    <metric>[item 0 feature] of patch 1 5</metric>
    <metric>[item 0 feature] of patch 1 6</metric>
    <metric>[item 0 feature] of patch 1 7</metric>
    <metric>[item 0 feature] of patch 1 8</metric>
    <metric>[item 0 feature] of patch 1 9</metric>
    <metric>[item 0 feature] of patch 2 0</metric>
    <metric>[item 0 feature] of patch 2 1</metric>
    <metric>[item 0 feature] of patch 2 2</metric>
    <metric>[item 0 feature] of patch 2 3</metric>
    <metric>[item 0 feature] of patch 2 4</metric>
    <metric>[item 0 feature] of patch 2 5</metric>
    <metric>[item 0 feature] of patch 2 6</metric>
    <metric>[item 0 feature] of patch 2 7</metric>
    <metric>[item 0 feature] of patch 2 8</metric>
    <metric>[item 0 feature] of patch 2 9</metric>
    <metric>[item 0 feature] of patch 3 0</metric>
    <metric>[item 0 feature] of patch 3 1</metric>
    <metric>[item 0 feature] of patch 3 2</metric>
    <metric>[item 0 feature] of patch 3 3</metric>
    <metric>[item 0 feature] of patch 3 4</metric>
    <metric>[item 0 feature] of patch 3 5</metric>
    <metric>[item 0 feature] of patch 3 6</metric>
    <metric>[item 0 feature] of patch 3 7</metric>
    <metric>[item 0 feature] of patch 3 8</metric>
    <metric>[item 0 feature] of patch 3 9</metric>
    <metric>[item 0 feature] of patch 4 0</metric>
    <metric>[item 0 feature] of patch 4 1</metric>
    <metric>[item 0 feature] of patch 4 2</metric>
    <metric>[item 0 feature] of patch 4 3</metric>
    <metric>[item 0 feature] of patch 4 4</metric>
    <metric>[item 0 feature] of patch 4 5</metric>
    <metric>[item 0 feature] of patch 4 6</metric>
    <metric>[item 0 feature] of patch 4 7</metric>
    <metric>[item 0 feature] of patch 4 8</metric>
    <metric>[item 0 feature] of patch 4 9</metric>
    <metric>[item 0 feature] of patch 5 0</metric>
    <metric>[item 0 feature] of patch 5 1</metric>
    <metric>[item 0 feature] of patch 5 2</metric>
    <metric>[item 0 feature] of patch 5 3</metric>
    <metric>[item 0 feature] of patch 5 4</metric>
    <metric>[item 0 feature] of patch 5 5</metric>
    <metric>[item 0 feature] of patch 5 6</metric>
    <metric>[item 0 feature] of patch 5 7</metric>
    <metric>[item 0 feature] of patch 5 8</metric>
    <metric>[item 0 feature] of patch 5 9</metric>
    <metric>[item 0 feature] of patch 6 0</metric>
    <metric>[item 0 feature] of patch 6 1</metric>
    <metric>[item 0 feature] of patch 6 2</metric>
    <metric>[item 0 feature] of patch 6 3</metric>
    <metric>[item 0 feature] of patch 6 4</metric>
    <metric>[item 0 feature] of patch 6 5</metric>
    <metric>[item 0 feature] of patch 6 6</metric>
    <metric>[item 0 feature] of patch 6 7</metric>
    <metric>[item 0 feature] of patch 6 8</metric>
    <metric>[item 0 feature] of patch 6 9</metric>
    <metric>[item 0 feature] of patch 7 0</metric>
    <metric>[item 0 feature] of patch 7 1</metric>
    <metric>[item 0 feature] of patch 7 2</metric>
    <metric>[item 0 feature] of patch 7 3</metric>
    <metric>[item 0 feature] of patch 7 4</metric>
    <metric>[item 0 feature] of patch 7 5</metric>
    <metric>[item 0 feature] of patch 7 6</metric>
    <metric>[item 0 feature] of patch 7 7</metric>
    <metric>[item 0 feature] of patch 7 8</metric>
    <metric>[item 0 feature] of patch 7 9</metric>
    <metric>[item 0 feature] of patch 8 0</metric>
    <metric>[item 0 feature] of patch 8 1</metric>
    <metric>[item 0 feature] of patch 8 2</metric>
    <metric>[item 0 feature] of patch 8 3</metric>
    <metric>[item 0 feature] of patch 8 4</metric>
    <metric>[item 0 feature] of patch 8 5</metric>
    <metric>[item 0 feature] of patch 8 6</metric>
    <metric>[item 0 feature] of patch 8 7</metric>
    <metric>[item 0 feature] of patch 8 8</metric>
    <metric>[item 0 feature] of patch 8 9</metric>
    <metric>[item 0 feature] of patch 9 0</metric>
    <metric>[item 0 feature] of patch 9 1</metric>
    <metric>[item 0 feature] of patch 9 2</metric>
    <metric>[item 0 feature] of patch 9 3</metric>
    <metric>[item 0 feature] of patch 9 4</metric>
    <metric>[item 0 feature] of patch 9 5</metric>
    <metric>[item 0 feature] of patch 9 6</metric>
    <metric>[item 0 feature] of patch 9 7</metric>
    <metric>[item 0 feature] of patch 9 8</metric>
    <metric>[item 0 feature] of patch 9 9</metric>
    <enumeratedValueSet variable="number_of_Features">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feature_move_method">
      <value value="&quot;midpoint&quot;"/>
      <value value="&quot;identical&quot;"/>
      <value value="&quot;randomly&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no_overlap_prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Random_interaction">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation_rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="report_CC">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Choose_feature_method">
      <value value="&quot;Most-similar&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range_of_interaction">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="One_feat_varying_how-move_tracking_values_100-go" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>repeat 100 [go]</go>
    <metric>standard-deviation [item 0 feature] of patches</metric>
    <metric>[item 0 feature] of patch 0 0</metric>
    <metric>[item 0 feature] of patch 0 1</metric>
    <metric>[item 0 feature] of patch 0 2</metric>
    <metric>[item 0 feature] of patch 0 3</metric>
    <metric>[item 0 feature] of patch 0 4</metric>
    <metric>[item 0 feature] of patch 0 5</metric>
    <metric>[item 0 feature] of patch 0 6</metric>
    <metric>[item 0 feature] of patch 0 7</metric>
    <metric>[item 0 feature] of patch 0 8</metric>
    <metric>[item 0 feature] of patch 0 9</metric>
    <metric>[item 0 feature] of patch 1 0</metric>
    <metric>[item 0 feature] of patch 1 1</metric>
    <metric>[item 0 feature] of patch 1 2</metric>
    <metric>[item 0 feature] of patch 1 3</metric>
    <metric>[item 0 feature] of patch 1 4</metric>
    <metric>[item 0 feature] of patch 1 5</metric>
    <metric>[item 0 feature] of patch 1 6</metric>
    <metric>[item 0 feature] of patch 1 7</metric>
    <metric>[item 0 feature] of patch 1 8</metric>
    <metric>[item 0 feature] of patch 1 9</metric>
    <metric>[item 0 feature] of patch 2 0</metric>
    <metric>[item 0 feature] of patch 2 1</metric>
    <metric>[item 0 feature] of patch 2 2</metric>
    <metric>[item 0 feature] of patch 2 3</metric>
    <metric>[item 0 feature] of patch 2 4</metric>
    <metric>[item 0 feature] of patch 2 5</metric>
    <metric>[item 0 feature] of patch 2 6</metric>
    <metric>[item 0 feature] of patch 2 7</metric>
    <metric>[item 0 feature] of patch 2 8</metric>
    <metric>[item 0 feature] of patch 2 9</metric>
    <metric>[item 0 feature] of patch 3 0</metric>
    <metric>[item 0 feature] of patch 3 1</metric>
    <metric>[item 0 feature] of patch 3 2</metric>
    <metric>[item 0 feature] of patch 3 3</metric>
    <metric>[item 0 feature] of patch 3 4</metric>
    <metric>[item 0 feature] of patch 3 5</metric>
    <metric>[item 0 feature] of patch 3 6</metric>
    <metric>[item 0 feature] of patch 3 7</metric>
    <metric>[item 0 feature] of patch 3 8</metric>
    <metric>[item 0 feature] of patch 3 9</metric>
    <metric>[item 0 feature] of patch 4 0</metric>
    <metric>[item 0 feature] of patch 4 1</metric>
    <metric>[item 0 feature] of patch 4 2</metric>
    <metric>[item 0 feature] of patch 4 3</metric>
    <metric>[item 0 feature] of patch 4 4</metric>
    <metric>[item 0 feature] of patch 4 5</metric>
    <metric>[item 0 feature] of patch 4 6</metric>
    <metric>[item 0 feature] of patch 4 7</metric>
    <metric>[item 0 feature] of patch 4 8</metric>
    <metric>[item 0 feature] of patch 4 9</metric>
    <metric>[item 0 feature] of patch 5 0</metric>
    <metric>[item 0 feature] of patch 5 1</metric>
    <metric>[item 0 feature] of patch 5 2</metric>
    <metric>[item 0 feature] of patch 5 3</metric>
    <metric>[item 0 feature] of patch 5 4</metric>
    <metric>[item 0 feature] of patch 5 5</metric>
    <metric>[item 0 feature] of patch 5 6</metric>
    <metric>[item 0 feature] of patch 5 7</metric>
    <metric>[item 0 feature] of patch 5 8</metric>
    <metric>[item 0 feature] of patch 5 9</metric>
    <metric>[item 0 feature] of patch 6 0</metric>
    <metric>[item 0 feature] of patch 6 1</metric>
    <metric>[item 0 feature] of patch 6 2</metric>
    <metric>[item 0 feature] of patch 6 3</metric>
    <metric>[item 0 feature] of patch 6 4</metric>
    <metric>[item 0 feature] of patch 6 5</metric>
    <metric>[item 0 feature] of patch 6 6</metric>
    <metric>[item 0 feature] of patch 6 7</metric>
    <metric>[item 0 feature] of patch 6 8</metric>
    <metric>[item 0 feature] of patch 6 9</metric>
    <metric>[item 0 feature] of patch 7 0</metric>
    <metric>[item 0 feature] of patch 7 1</metric>
    <metric>[item 0 feature] of patch 7 2</metric>
    <metric>[item 0 feature] of patch 7 3</metric>
    <metric>[item 0 feature] of patch 7 4</metric>
    <metric>[item 0 feature] of patch 7 5</metric>
    <metric>[item 0 feature] of patch 7 6</metric>
    <metric>[item 0 feature] of patch 7 7</metric>
    <metric>[item 0 feature] of patch 7 8</metric>
    <metric>[item 0 feature] of patch 7 9</metric>
    <metric>[item 0 feature] of patch 8 0</metric>
    <metric>[item 0 feature] of patch 8 1</metric>
    <metric>[item 0 feature] of patch 8 2</metric>
    <metric>[item 0 feature] of patch 8 3</metric>
    <metric>[item 0 feature] of patch 8 4</metric>
    <metric>[item 0 feature] of patch 8 5</metric>
    <metric>[item 0 feature] of patch 8 6</metric>
    <metric>[item 0 feature] of patch 8 7</metric>
    <metric>[item 0 feature] of patch 8 8</metric>
    <metric>[item 0 feature] of patch 8 9</metric>
    <metric>[item 0 feature] of patch 9 0</metric>
    <metric>[item 0 feature] of patch 9 1</metric>
    <metric>[item 0 feature] of patch 9 2</metric>
    <metric>[item 0 feature] of patch 9 3</metric>
    <metric>[item 0 feature] of patch 9 4</metric>
    <metric>[item 0 feature] of patch 9 5</metric>
    <metric>[item 0 feature] of patch 9 6</metric>
    <metric>[item 0 feature] of patch 9 7</metric>
    <metric>[item 0 feature] of patch 9 8</metric>
    <metric>[item 0 feature] of patch 9 9</metric>
    <enumeratedValueSet variable="number_of_Features">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feature_move_method">
      <value value="&quot;midpoint&quot;"/>
      <value value="&quot;identical&quot;"/>
      <value value="&quot;randomly&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no_overlap_prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Random_interaction">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation_rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="report_CC">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Choose_feature_method">
      <value value="&quot;Most-similar&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range_of_interaction">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="FiveFeatures_AllMethods_TrackingAll_n5_100go" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>repeat 100 [go]</go>
    <timeLimit steps="250005"/>
    <metric>standard-deviation [item 0 feature] of patches</metric>
    <metric>standard-deviation [item 1 feature] of patches</metric>
    <metric>standard-deviation [item 2 feature] of patches</metric>
    <metric>standard-deviation [item 3 feature] of patches</metric>
    <metric>standard-deviation [item 4 feature] of patches</metric>
    <metric>[item 0 feature] of patch 0 0</metric>
    <metric>[item 0 feature] of patch 0 1</metric>
    <metric>[item 0 feature] of patch 0 2</metric>
    <metric>[item 0 feature] of patch 0 3</metric>
    <metric>[item 0 feature] of patch 0 4</metric>
    <metric>[item 0 feature] of patch 0 5</metric>
    <metric>[item 0 feature] of patch 0 6</metric>
    <metric>[item 0 feature] of patch 0 7</metric>
    <metric>[item 0 feature] of patch 0 8</metric>
    <metric>[item 0 feature] of patch 0 9</metric>
    <metric>[item 0 feature] of patch 1 0</metric>
    <metric>[item 0 feature] of patch 1 1</metric>
    <metric>[item 0 feature] of patch 1 2</metric>
    <metric>[item 0 feature] of patch 1 3</metric>
    <metric>[item 0 feature] of patch 1 4</metric>
    <metric>[item 0 feature] of patch 1 5</metric>
    <metric>[item 0 feature] of patch 1 6</metric>
    <metric>[item 0 feature] of patch 1 7</metric>
    <metric>[item 0 feature] of patch 1 8</metric>
    <metric>[item 0 feature] of patch 1 9</metric>
    <metric>[item 0 feature] of patch 2 0</metric>
    <metric>[item 0 feature] of patch 2 1</metric>
    <metric>[item 0 feature] of patch 2 2</metric>
    <metric>[item 0 feature] of patch 2 3</metric>
    <metric>[item 0 feature] of patch 2 4</metric>
    <metric>[item 0 feature] of patch 2 5</metric>
    <metric>[item 0 feature] of patch 2 6</metric>
    <metric>[item 0 feature] of patch 2 7</metric>
    <metric>[item 0 feature] of patch 2 8</metric>
    <metric>[item 0 feature] of patch 2 9</metric>
    <metric>[item 0 feature] of patch 3 0</metric>
    <metric>[item 0 feature] of patch 3 1</metric>
    <metric>[item 0 feature] of patch 3 2</metric>
    <metric>[item 0 feature] of patch 3 3</metric>
    <metric>[item 0 feature] of patch 3 4</metric>
    <metric>[item 0 feature] of patch 3 5</metric>
    <metric>[item 0 feature] of patch 3 6</metric>
    <metric>[item 0 feature] of patch 3 7</metric>
    <metric>[item 0 feature] of patch 3 8</metric>
    <metric>[item 0 feature] of patch 3 9</metric>
    <metric>[item 0 feature] of patch 4 0</metric>
    <metric>[item 0 feature] of patch 4 1</metric>
    <metric>[item 0 feature] of patch 4 2</metric>
    <metric>[item 0 feature] of patch 4 3</metric>
    <metric>[item 0 feature] of patch 4 4</metric>
    <metric>[item 0 feature] of patch 4 5</metric>
    <metric>[item 0 feature] of patch 4 6</metric>
    <metric>[item 0 feature] of patch 4 7</metric>
    <metric>[item 0 feature] of patch 4 8</metric>
    <metric>[item 0 feature] of patch 4 9</metric>
    <metric>[item 0 feature] of patch 5 0</metric>
    <metric>[item 0 feature] of patch 5 1</metric>
    <metric>[item 0 feature] of patch 5 2</metric>
    <metric>[item 0 feature] of patch 5 3</metric>
    <metric>[item 0 feature] of patch 5 4</metric>
    <metric>[item 0 feature] of patch 5 5</metric>
    <metric>[item 0 feature] of patch 5 6</metric>
    <metric>[item 0 feature] of patch 5 7</metric>
    <metric>[item 0 feature] of patch 5 8</metric>
    <metric>[item 0 feature] of patch 5 9</metric>
    <metric>[item 0 feature] of patch 6 0</metric>
    <metric>[item 0 feature] of patch 6 1</metric>
    <metric>[item 0 feature] of patch 6 2</metric>
    <metric>[item 0 feature] of patch 6 3</metric>
    <metric>[item 0 feature] of patch 6 4</metric>
    <metric>[item 0 feature] of patch 6 5</metric>
    <metric>[item 0 feature] of patch 6 6</metric>
    <metric>[item 0 feature] of patch 6 7</metric>
    <metric>[item 0 feature] of patch 6 8</metric>
    <metric>[item 0 feature] of patch 6 9</metric>
    <metric>[item 0 feature] of patch 7 0</metric>
    <metric>[item 0 feature] of patch 7 1</metric>
    <metric>[item 0 feature] of patch 7 2</metric>
    <metric>[item 0 feature] of patch 7 3</metric>
    <metric>[item 0 feature] of patch 7 4</metric>
    <metric>[item 0 feature] of patch 7 5</metric>
    <metric>[item 0 feature] of patch 7 6</metric>
    <metric>[item 0 feature] of patch 7 7</metric>
    <metric>[item 0 feature] of patch 7 8</metric>
    <metric>[item 0 feature] of patch 7 9</metric>
    <metric>[item 0 feature] of patch 8 0</metric>
    <metric>[item 0 feature] of patch 8 1</metric>
    <metric>[item 0 feature] of patch 8 2</metric>
    <metric>[item 0 feature] of patch 8 3</metric>
    <metric>[item 0 feature] of patch 8 4</metric>
    <metric>[item 0 feature] of patch 8 5</metric>
    <metric>[item 0 feature] of patch 8 6</metric>
    <metric>[item 0 feature] of patch 8 7</metric>
    <metric>[item 0 feature] of patch 8 8</metric>
    <metric>[item 0 feature] of patch 8 9</metric>
    <metric>[item 0 feature] of patch 9 0</metric>
    <metric>[item 0 feature] of patch 9 1</metric>
    <metric>[item 0 feature] of patch 9 2</metric>
    <metric>[item 0 feature] of patch 9 3</metric>
    <metric>[item 0 feature] of patch 9 4</metric>
    <metric>[item 0 feature] of patch 9 5</metric>
    <metric>[item 0 feature] of patch 9 6</metric>
    <metric>[item 0 feature] of patch 9 7</metric>
    <metric>[item 0 feature] of patch 9 8</metric>
    <metric>[item 0 feature] of patch 9 9</metric>
    <metric>[item 1 feature] of patch 0 0</metric>
    <metric>[item 1 feature] of patch 0 1</metric>
    <metric>[item 1 feature] of patch 0 2</metric>
    <metric>[item 1 feature] of patch 0 3</metric>
    <metric>[item 1 feature] of patch 0 4</metric>
    <metric>[item 1 feature] of patch 0 5</metric>
    <metric>[item 1 feature] of patch 0 6</metric>
    <metric>[item 1 feature] of patch 0 7</metric>
    <metric>[item 1 feature] of patch 0 8</metric>
    <metric>[item 1 feature] of patch 0 9</metric>
    <metric>[item 1 feature] of patch 1 0</metric>
    <metric>[item 1 feature] of patch 1 1</metric>
    <metric>[item 1 feature] of patch 1 2</metric>
    <metric>[item 1 feature] of patch 1 3</metric>
    <metric>[item 1 feature] of patch 1 4</metric>
    <metric>[item 1 feature] of patch 1 5</metric>
    <metric>[item 1 feature] of patch 1 6</metric>
    <metric>[item 1 feature] of patch 1 7</metric>
    <metric>[item 1 feature] of patch 1 8</metric>
    <metric>[item 1 feature] of patch 1 9</metric>
    <metric>[item 1 feature] of patch 2 0</metric>
    <metric>[item 1 feature] of patch 2 1</metric>
    <metric>[item 1 feature] of patch 2 2</metric>
    <metric>[item 1 feature] of patch 2 3</metric>
    <metric>[item 1 feature] of patch 2 4</metric>
    <metric>[item 1 feature] of patch 2 5</metric>
    <metric>[item 1 feature] of patch 2 6</metric>
    <metric>[item 1 feature] of patch 2 7</metric>
    <metric>[item 1 feature] of patch 2 8</metric>
    <metric>[item 1 feature] of patch 2 9</metric>
    <metric>[item 1 feature] of patch 3 0</metric>
    <metric>[item 1 feature] of patch 3 1</metric>
    <metric>[item 1 feature] of patch 3 2</metric>
    <metric>[item 1 feature] of patch 3 3</metric>
    <metric>[item 1 feature] of patch 3 4</metric>
    <metric>[item 1 feature] of patch 3 5</metric>
    <metric>[item 1 feature] of patch 3 6</metric>
    <metric>[item 1 feature] of patch 3 7</metric>
    <metric>[item 1 feature] of patch 3 8</metric>
    <metric>[item 1 feature] of patch 3 9</metric>
    <metric>[item 1 feature] of patch 4 0</metric>
    <metric>[item 1 feature] of patch 4 1</metric>
    <metric>[item 1 feature] of patch 4 2</metric>
    <metric>[item 1 feature] of patch 4 3</metric>
    <metric>[item 1 feature] of patch 4 4</metric>
    <metric>[item 1 feature] of patch 4 5</metric>
    <metric>[item 1 feature] of patch 4 6</metric>
    <metric>[item 1 feature] of patch 4 7</metric>
    <metric>[item 1 feature] of patch 4 8</metric>
    <metric>[item 1 feature] of patch 4 9</metric>
    <metric>[item 1 feature] of patch 5 0</metric>
    <metric>[item 1 feature] of patch 5 1</metric>
    <metric>[item 1 feature] of patch 5 2</metric>
    <metric>[item 1 feature] of patch 5 3</metric>
    <metric>[item 1 feature] of patch 5 4</metric>
    <metric>[item 1 feature] of patch 5 5</metric>
    <metric>[item 1 feature] of patch 5 6</metric>
    <metric>[item 1 feature] of patch 5 7</metric>
    <metric>[item 1 feature] of patch 5 8</metric>
    <metric>[item 1 feature] of patch 5 9</metric>
    <metric>[item 1 feature] of patch 6 0</metric>
    <metric>[item 1 feature] of patch 6 1</metric>
    <metric>[item 1 feature] of patch 6 2</metric>
    <metric>[item 1 feature] of patch 6 3</metric>
    <metric>[item 1 feature] of patch 6 4</metric>
    <metric>[item 1 feature] of patch 6 5</metric>
    <metric>[item 1 feature] of patch 6 6</metric>
    <metric>[item 1 feature] of patch 6 7</metric>
    <metric>[item 1 feature] of patch 6 8</metric>
    <metric>[item 1 feature] of patch 6 9</metric>
    <metric>[item 1 feature] of patch 7 0</metric>
    <metric>[item 1 feature] of patch 7 1</metric>
    <metric>[item 1 feature] of patch 7 2</metric>
    <metric>[item 1 feature] of patch 7 3</metric>
    <metric>[item 1 feature] of patch 7 4</metric>
    <metric>[item 1 feature] of patch 7 5</metric>
    <metric>[item 1 feature] of patch 7 6</metric>
    <metric>[item 1 feature] of patch 7 7</metric>
    <metric>[item 1 feature] of patch 7 8</metric>
    <metric>[item 1 feature] of patch 7 9</metric>
    <metric>[item 1 feature] of patch 8 0</metric>
    <metric>[item 1 feature] of patch 8 1</metric>
    <metric>[item 1 feature] of patch 8 2</metric>
    <metric>[item 1 feature] of patch 8 3</metric>
    <metric>[item 1 feature] of patch 8 4</metric>
    <metric>[item 1 feature] of patch 8 5</metric>
    <metric>[item 1 feature] of patch 8 6</metric>
    <metric>[item 1 feature] of patch 8 7</metric>
    <metric>[item 1 feature] of patch 8 8</metric>
    <metric>[item 1 feature] of patch 8 9</metric>
    <metric>[item 1 feature] of patch 9 0</metric>
    <metric>[item 1 feature] of patch 9 1</metric>
    <metric>[item 1 feature] of patch 9 2</metric>
    <metric>[item 1 feature] of patch 9 3</metric>
    <metric>[item 1 feature] of patch 9 4</metric>
    <metric>[item 1 feature] of patch 9 5</metric>
    <metric>[item 1 feature] of patch 9 6</metric>
    <metric>[item 1 feature] of patch 9 7</metric>
    <metric>[item 1 feature] of patch 9 8</metric>
    <metric>[item 1 feature] of patch 9 9</metric>
    <metric>[item 2 feature] of patch 0 0</metric>
    <metric>[item 2 feature] of patch 0 1</metric>
    <metric>[item 2 feature] of patch 0 2</metric>
    <metric>[item 2 feature] of patch 0 3</metric>
    <metric>[item 2 feature] of patch 0 4</metric>
    <metric>[item 2 feature] of patch 0 5</metric>
    <metric>[item 2 feature] of patch 0 6</metric>
    <metric>[item 2 feature] of patch 0 7</metric>
    <metric>[item 2 feature] of patch 0 8</metric>
    <metric>[item 2 feature] of patch 0 9</metric>
    <metric>[item 2 feature] of patch 1 0</metric>
    <metric>[item 2 feature] of patch 1 1</metric>
    <metric>[item 2 feature] of patch 1 2</metric>
    <metric>[item 2 feature] of patch 1 3</metric>
    <metric>[item 2 feature] of patch 1 4</metric>
    <metric>[item 2 feature] of patch 1 5</metric>
    <metric>[item 2 feature] of patch 1 6</metric>
    <metric>[item 2 feature] of patch 1 7</metric>
    <metric>[item 2 feature] of patch 1 8</metric>
    <metric>[item 2 feature] of patch 1 9</metric>
    <metric>[item 2 feature] of patch 2 0</metric>
    <metric>[item 2 feature] of patch 2 1</metric>
    <metric>[item 2 feature] of patch 2 2</metric>
    <metric>[item 2 feature] of patch 2 3</metric>
    <metric>[item 2 feature] of patch 2 4</metric>
    <metric>[item 2 feature] of patch 2 5</metric>
    <metric>[item 2 feature] of patch 2 6</metric>
    <metric>[item 2 feature] of patch 2 7</metric>
    <metric>[item 2 feature] of patch 2 8</metric>
    <metric>[item 2 feature] of patch 2 9</metric>
    <metric>[item 2 feature] of patch 3 0</metric>
    <metric>[item 2 feature] of patch 3 1</metric>
    <metric>[item 2 feature] of patch 3 2</metric>
    <metric>[item 2 feature] of patch 3 3</metric>
    <metric>[item 2 feature] of patch 3 4</metric>
    <metric>[item 2 feature] of patch 3 5</metric>
    <metric>[item 2 feature] of patch 3 6</metric>
    <metric>[item 2 feature] of patch 3 7</metric>
    <metric>[item 2 feature] of patch 3 8</metric>
    <metric>[item 2 feature] of patch 3 9</metric>
    <metric>[item 2 feature] of patch 4 0</metric>
    <metric>[item 2 feature] of patch 4 1</metric>
    <metric>[item 2 feature] of patch 4 2</metric>
    <metric>[item 2 feature] of patch 4 3</metric>
    <metric>[item 2 feature] of patch 4 4</metric>
    <metric>[item 2 feature] of patch 4 5</metric>
    <metric>[item 2 feature] of patch 4 6</metric>
    <metric>[item 2 feature] of patch 4 7</metric>
    <metric>[item 2 feature] of patch 4 8</metric>
    <metric>[item 2 feature] of patch 4 9</metric>
    <metric>[item 2 feature] of patch 5 0</metric>
    <metric>[item 2 feature] of patch 5 1</metric>
    <metric>[item 2 feature] of patch 5 2</metric>
    <metric>[item 2 feature] of patch 5 3</metric>
    <metric>[item 2 feature] of patch 5 4</metric>
    <metric>[item 2 feature] of patch 5 5</metric>
    <metric>[item 2 feature] of patch 5 6</metric>
    <metric>[item 2 feature] of patch 5 7</metric>
    <metric>[item 2 feature] of patch 5 8</metric>
    <metric>[item 2 feature] of patch 5 9</metric>
    <metric>[item 2 feature] of patch 6 0</metric>
    <metric>[item 2 feature] of patch 6 1</metric>
    <metric>[item 2 feature] of patch 6 2</metric>
    <metric>[item 2 feature] of patch 6 3</metric>
    <metric>[item 2 feature] of patch 6 4</metric>
    <metric>[item 2 feature] of patch 6 5</metric>
    <metric>[item 2 feature] of patch 6 6</metric>
    <metric>[item 2 feature] of patch 6 7</metric>
    <metric>[item 2 feature] of patch 6 8</metric>
    <metric>[item 2 feature] of patch 6 9</metric>
    <metric>[item 2 feature] of patch 7 0</metric>
    <metric>[item 2 feature] of patch 7 1</metric>
    <metric>[item 2 feature] of patch 7 2</metric>
    <metric>[item 2 feature] of patch 7 3</metric>
    <metric>[item 2 feature] of patch 7 4</metric>
    <metric>[item 2 feature] of patch 7 5</metric>
    <metric>[item 2 feature] of patch 7 6</metric>
    <metric>[item 2 feature] of patch 7 7</metric>
    <metric>[item 2 feature] of patch 7 8</metric>
    <metric>[item 2 feature] of patch 7 9</metric>
    <metric>[item 2 feature] of patch 8 0</metric>
    <metric>[item 2 feature] of patch 8 1</metric>
    <metric>[item 2 feature] of patch 8 2</metric>
    <metric>[item 2 feature] of patch 8 3</metric>
    <metric>[item 2 feature] of patch 8 4</metric>
    <metric>[item 2 feature] of patch 8 5</metric>
    <metric>[item 2 feature] of patch 8 6</metric>
    <metric>[item 2 feature] of patch 8 7</metric>
    <metric>[item 2 feature] of patch 8 8</metric>
    <metric>[item 2 feature] of patch 8 9</metric>
    <metric>[item 2 feature] of patch 9 0</metric>
    <metric>[item 2 feature] of patch 9 1</metric>
    <metric>[item 2 feature] of patch 9 2</metric>
    <metric>[item 2 feature] of patch 9 3</metric>
    <metric>[item 2 feature] of patch 9 4</metric>
    <metric>[item 2 feature] of patch 9 5</metric>
    <metric>[item 2 feature] of patch 9 6</metric>
    <metric>[item 2 feature] of patch 9 7</metric>
    <metric>[item 2 feature] of patch 9 8</metric>
    <metric>[item 2 feature] of patch 9 9</metric>
    <metric>[item 3 feature] of patch 0 0</metric>
    <metric>[item 3 feature] of patch 0 1</metric>
    <metric>[item 3 feature] of patch 0 2</metric>
    <metric>[item 3 feature] of patch 0 3</metric>
    <metric>[item 3 feature] of patch 0 4</metric>
    <metric>[item 3 feature] of patch 0 5</metric>
    <metric>[item 3 feature] of patch 0 6</metric>
    <metric>[item 3 feature] of patch 0 7</metric>
    <metric>[item 3 feature] of patch 0 8</metric>
    <metric>[item 3 feature] of patch 0 9</metric>
    <metric>[item 3 feature] of patch 1 0</metric>
    <metric>[item 3 feature] of patch 1 1</metric>
    <metric>[item 3 feature] of patch 1 2</metric>
    <metric>[item 3 feature] of patch 1 3</metric>
    <metric>[item 3 feature] of patch 1 4</metric>
    <metric>[item 3 feature] of patch 1 5</metric>
    <metric>[item 3 feature] of patch 1 6</metric>
    <metric>[item 3 feature] of patch 1 7</metric>
    <metric>[item 3 feature] of patch 1 8</metric>
    <metric>[item 3 feature] of patch 1 9</metric>
    <metric>[item 3 feature] of patch 2 0</metric>
    <metric>[item 3 feature] of patch 2 1</metric>
    <metric>[item 3 feature] of patch 2 2</metric>
    <metric>[item 3 feature] of patch 2 3</metric>
    <metric>[item 3 feature] of patch 2 4</metric>
    <metric>[item 3 feature] of patch 2 5</metric>
    <metric>[item 3 feature] of patch 2 6</metric>
    <metric>[item 3 feature] of patch 2 7</metric>
    <metric>[item 3 feature] of patch 2 8</metric>
    <metric>[item 3 feature] of patch 2 9</metric>
    <metric>[item 3 feature] of patch 3 0</metric>
    <metric>[item 3 feature] of patch 3 1</metric>
    <metric>[item 3 feature] of patch 3 2</metric>
    <metric>[item 3 feature] of patch 3 3</metric>
    <metric>[item 3 feature] of patch 3 4</metric>
    <metric>[item 3 feature] of patch 3 5</metric>
    <metric>[item 3 feature] of patch 3 6</metric>
    <metric>[item 3 feature] of patch 3 7</metric>
    <metric>[item 3 feature] of patch 3 8</metric>
    <metric>[item 3 feature] of patch 3 9</metric>
    <metric>[item 3 feature] of patch 4 0</metric>
    <metric>[item 3 feature] of patch 4 1</metric>
    <metric>[item 3 feature] of patch 4 2</metric>
    <metric>[item 3 feature] of patch 4 3</metric>
    <metric>[item 3 feature] of patch 4 4</metric>
    <metric>[item 3 feature] of patch 4 5</metric>
    <metric>[item 3 feature] of patch 4 6</metric>
    <metric>[item 3 feature] of patch 4 7</metric>
    <metric>[item 3 feature] of patch 4 8</metric>
    <metric>[item 3 feature] of patch 4 9</metric>
    <metric>[item 3 feature] of patch 5 0</metric>
    <metric>[item 3 feature] of patch 5 1</metric>
    <metric>[item 3 feature] of patch 5 2</metric>
    <metric>[item 3 feature] of patch 5 3</metric>
    <metric>[item 3 feature] of patch 5 4</metric>
    <metric>[item 3 feature] of patch 5 5</metric>
    <metric>[item 3 feature] of patch 5 6</metric>
    <metric>[item 3 feature] of patch 5 7</metric>
    <metric>[item 3 feature] of patch 5 8</metric>
    <metric>[item 3 feature] of patch 5 9</metric>
    <metric>[item 3 feature] of patch 6 0</metric>
    <metric>[item 3 feature] of patch 6 1</metric>
    <metric>[item 3 feature] of patch 6 2</metric>
    <metric>[item 3 feature] of patch 6 3</metric>
    <metric>[item 3 feature] of patch 6 4</metric>
    <metric>[item 3 feature] of patch 6 5</metric>
    <metric>[item 3 feature] of patch 6 6</metric>
    <metric>[item 3 feature] of patch 6 7</metric>
    <metric>[item 3 feature] of patch 6 8</metric>
    <metric>[item 3 feature] of patch 6 9</metric>
    <metric>[item 3 feature] of patch 7 0</metric>
    <metric>[item 3 feature] of patch 7 1</metric>
    <metric>[item 3 feature] of patch 7 2</metric>
    <metric>[item 3 feature] of patch 7 3</metric>
    <metric>[item 3 feature] of patch 7 4</metric>
    <metric>[item 3 feature] of patch 7 5</metric>
    <metric>[item 3 feature] of patch 7 6</metric>
    <metric>[item 3 feature] of patch 7 7</metric>
    <metric>[item 3 feature] of patch 7 8</metric>
    <metric>[item 3 feature] of patch 7 9</metric>
    <metric>[item 3 feature] of patch 8 0</metric>
    <metric>[item 3 feature] of patch 8 1</metric>
    <metric>[item 3 feature] of patch 8 2</metric>
    <metric>[item 3 feature] of patch 8 3</metric>
    <metric>[item 3 feature] of patch 8 4</metric>
    <metric>[item 3 feature] of patch 8 5</metric>
    <metric>[item 3 feature] of patch 8 6</metric>
    <metric>[item 3 feature] of patch 8 7</metric>
    <metric>[item 3 feature] of patch 8 8</metric>
    <metric>[item 3 feature] of patch 8 9</metric>
    <metric>[item 3 feature] of patch 9 0</metric>
    <metric>[item 3 feature] of patch 9 1</metric>
    <metric>[item 3 feature] of patch 9 2</metric>
    <metric>[item 3 feature] of patch 9 3</metric>
    <metric>[item 3 feature] of patch 9 4</metric>
    <metric>[item 3 feature] of patch 9 5</metric>
    <metric>[item 3 feature] of patch 9 6</metric>
    <metric>[item 3 feature] of patch 9 7</metric>
    <metric>[item 3 feature] of patch 9 8</metric>
    <metric>[item 3 feature] of patch 9 9</metric>
    <metric>[item 4 feature] of patch 0 0</metric>
    <metric>[item 4 feature] of patch 0 1</metric>
    <metric>[item 4 feature] of patch 0 2</metric>
    <metric>[item 4 feature] of patch 0 3</metric>
    <metric>[item 4 feature] of patch 0 4</metric>
    <metric>[item 4 feature] of patch 0 5</metric>
    <metric>[item 4 feature] of patch 0 6</metric>
    <metric>[item 4 feature] of patch 0 7</metric>
    <metric>[item 4 feature] of patch 0 8</metric>
    <metric>[item 4 feature] of patch 0 9</metric>
    <metric>[item 4 feature] of patch 1 0</metric>
    <metric>[item 4 feature] of patch 1 1</metric>
    <metric>[item 4 feature] of patch 1 2</metric>
    <metric>[item 4 feature] of patch 1 3</metric>
    <metric>[item 4 feature] of patch 1 4</metric>
    <metric>[item 4 feature] of patch 1 5</metric>
    <metric>[item 4 feature] of patch 1 6</metric>
    <metric>[item 4 feature] of patch 1 7</metric>
    <metric>[item 4 feature] of patch 1 8</metric>
    <metric>[item 4 feature] of patch 1 9</metric>
    <metric>[item 4 feature] of patch 2 0</metric>
    <metric>[item 4 feature] of patch 2 1</metric>
    <metric>[item 4 feature] of patch 2 2</metric>
    <metric>[item 4 feature] of patch 2 3</metric>
    <metric>[item 4 feature] of patch 2 4</metric>
    <metric>[item 4 feature] of patch 2 5</metric>
    <metric>[item 4 feature] of patch 2 6</metric>
    <metric>[item 4 feature] of patch 2 7</metric>
    <metric>[item 4 feature] of patch 2 8</metric>
    <metric>[item 4 feature] of patch 2 9</metric>
    <metric>[item 4 feature] of patch 3 0</metric>
    <metric>[item 4 feature] of patch 3 1</metric>
    <metric>[item 4 feature] of patch 3 2</metric>
    <metric>[item 4 feature] of patch 3 3</metric>
    <metric>[item 4 feature] of patch 3 4</metric>
    <metric>[item 4 feature] of patch 3 5</metric>
    <metric>[item 4 feature] of patch 3 6</metric>
    <metric>[item 4 feature] of patch 3 7</metric>
    <metric>[item 4 feature] of patch 3 8</metric>
    <metric>[item 4 feature] of patch 3 9</metric>
    <metric>[item 4 feature] of patch 4 0</metric>
    <metric>[item 4 feature] of patch 4 1</metric>
    <metric>[item 4 feature] of patch 4 2</metric>
    <metric>[item 4 feature] of patch 4 3</metric>
    <metric>[item 4 feature] of patch 4 4</metric>
    <metric>[item 4 feature] of patch 4 5</metric>
    <metric>[item 4 feature] of patch 4 6</metric>
    <metric>[item 4 feature] of patch 4 7</metric>
    <metric>[item 4 feature] of patch 4 8</metric>
    <metric>[item 4 feature] of patch 4 9</metric>
    <metric>[item 4 feature] of patch 5 0</metric>
    <metric>[item 4 feature] of patch 5 1</metric>
    <metric>[item 4 feature] of patch 5 2</metric>
    <metric>[item 4 feature] of patch 5 3</metric>
    <metric>[item 4 feature] of patch 5 4</metric>
    <metric>[item 4 feature] of patch 5 5</metric>
    <metric>[item 4 feature] of patch 5 6</metric>
    <metric>[item 4 feature] of patch 5 7</metric>
    <metric>[item 4 feature] of patch 5 8</metric>
    <metric>[item 4 feature] of patch 5 9</metric>
    <metric>[item 4 feature] of patch 6 0</metric>
    <metric>[item 4 feature] of patch 6 1</metric>
    <metric>[item 4 feature] of patch 6 2</metric>
    <metric>[item 4 feature] of patch 6 3</metric>
    <metric>[item 4 feature] of patch 6 4</metric>
    <metric>[item 4 feature] of patch 6 5</metric>
    <metric>[item 4 feature] of patch 6 6</metric>
    <metric>[item 4 feature] of patch 6 7</metric>
    <metric>[item 4 feature] of patch 6 8</metric>
    <metric>[item 4 feature] of patch 6 9</metric>
    <metric>[item 4 feature] of patch 7 0</metric>
    <metric>[item 4 feature] of patch 7 1</metric>
    <metric>[item 4 feature] of patch 7 2</metric>
    <metric>[item 4 feature] of patch 7 3</metric>
    <metric>[item 4 feature] of patch 7 4</metric>
    <metric>[item 4 feature] of patch 7 5</metric>
    <metric>[item 4 feature] of patch 7 6</metric>
    <metric>[item 4 feature] of patch 7 7</metric>
    <metric>[item 4 feature] of patch 7 8</metric>
    <metric>[item 4 feature] of patch 7 9</metric>
    <metric>[item 4 feature] of patch 8 0</metric>
    <metric>[item 4 feature] of patch 8 1</metric>
    <metric>[item 4 feature] of patch 8 2</metric>
    <metric>[item 4 feature] of patch 8 3</metric>
    <metric>[item 4 feature] of patch 8 4</metric>
    <metric>[item 4 feature] of patch 8 5</metric>
    <metric>[item 4 feature] of patch 8 6</metric>
    <metric>[item 4 feature] of patch 8 7</metric>
    <metric>[item 4 feature] of patch 8 8</metric>
    <metric>[item 4 feature] of patch 8 9</metric>
    <metric>[item 4 feature] of patch 9 0</metric>
    <metric>[item 4 feature] of patch 9 1</metric>
    <metric>[item 4 feature] of patch 9 2</metric>
    <metric>[item 4 feature] of patch 9 3</metric>
    <metric>[item 4 feature] of patch 9 4</metric>
    <metric>[item 4 feature] of patch 9 5</metric>
    <metric>[item 4 feature] of patch 9 6</metric>
    <metric>[item 4 feature] of patch 9 7</metric>
    <metric>[item 4 feature] of patch 9 8</metric>
    <metric>[item 4 feature] of patch 9 9</metric>
    <enumeratedValueSet variable="feature_move_method">
      <value value="&quot;randomly&quot;"/>
      <value value="&quot;midpoint&quot;"/>
      <value value="&quot;identical&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Choose_feature_method">
      <value value="&quot;Randomly&quot;"/>
      <value value="&quot;Most-dissimilar&quot;"/>
      <value value="&quot;Most-similar&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_of_Features">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no_overlap_prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Random_interaction">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation_rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="report_CC">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range_of_interaction">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Big_n_only_ticks_and_SDs" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="250005"/>
    <metric>standard-deviation [item 0 feature] of patches</metric>
    <metric>standard-deviation [item 1 feature] of patches</metric>
    <metric>standard-deviation [item 2 feature] of patches</metric>
    <metric>standard-deviation [item 3 feature] of patches</metric>
    <metric>standard-deviation [item 4 feature] of patches</metric>
    <metric>Ticks</metric>
    <enumeratedValueSet variable="feature_move_method">
      <value value="&quot;randomly&quot;"/>
      <value value="&quot;midpoint&quot;"/>
      <value value="&quot;identical&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Choose_feature_method">
      <value value="&quot;Randomly&quot;"/>
      <value value="&quot;Most-dissimilar&quot;"/>
      <value value="&quot;Most-similar&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_of_Features">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range_of_interaction">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no_overlap_prob">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Random_interaction">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation_rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="report_CC">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
