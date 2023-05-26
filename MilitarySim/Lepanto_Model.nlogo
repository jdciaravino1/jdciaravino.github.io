Globals [
  starting-seed
]


;;; Set variables. Breeds for each flank and reserve.
breed [hl_galleysr hl_galleyr] ;;Holy League galleys (landside)
breed [hl_galleysc hl_galleyc] ;;Holy League galleys (center)
breed [hl_galleysl hl_galleyl] ;;Holy League galleys (seaside)
breed [hl_galleasses galleass] ;;galleass (only 6)
breed [o_galleysr o_galleyr] ;;ottoman galleys (landside)
breed [o_galleysc o_galleyc] ;;ottoman galleys (center)
breed [o_galleysl o_galleyl] ;;ottoman galleys (seaside)
breed [o_flag_galliots flag_galliot] ;;galliots (only 10)

;;; Define variables to be able to model the galley/galleass
turtles-own[
 gun_power ;representative of the number of guns on board
 gunpowder ; damage delt per fire hit
 infantry_health ;affects speed, inoperable and hit damage for infantry. This is 0 for large ships
 infantry_dmg; amount of damage infantry hit with it
 infantry_hit_prob ;hit probability of infantry
 speed ;function of weight
 status ;inoperable/operable - below 20% health is inoperable
 current_attack_status ;either valid target, or not valid, 3-4 ships already attacking it.
 target_enemy ; target ship is targetting onto, if present
 hit_probability ; probability the gun hits the target
 infantry_hit_probability ;probability infantry kills enemy
 allegiance; Holy League/Ottoman Empire variable to determine which side unit is on
 weight; effect speeds
 turn; actively turning? T/F
 enemy_count; number of enemies in same space
 board_status; actively boarding another ship? gives the ship 1 tick to reboard their own ship to begin movement.
]

;;; Define patch level variables
patches-own [
  patch-hl-occupancy ;number of HL ships in one patch
  patch-o-occupancy ;number of o ships in one patch
  patch-total-occupancy ;total number of ships in one patch
]

;;; Defining global variables
globals [
  holy_league_const
  ottomon_empire_const
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;  utilities procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Gets closest HL enemy (enemies are Ottomans) within the specified range, empty is no enemy in range
; @param self_hl_ship: HL ship
; @param ship_range: range to search enemies within
; @return closest enemy ship if in range, nobody otherwise
to-report get_hl_ship_closest_enemy [self_hl_ship ship_range]
  let is_r_range enemy_in_range self_hl_ship o_galleysr ship_range
  let is_c_range enemy_in_range self_hl_ship o_galleysc ship_range
  let is_l_range enemy_in_range self_hl_ship o_galleysl ship_range
  let is_galliot_range enemy_in_range self_hl_ship o_flag_galliots ship_range
  (ifelse
    is_r_range = true [
      report get_closest_item self_hl_ship o_galleysr
    ]
    is_c_range = true [
      report get_closest_item self_hl_ship o_galleysc
    ]
    is_l_range = true [
      report get_closest_item self_hl_ship o_galleysl
    ]
    is_galliot_range = true [
      report get_closest_item self_hl_ship o_flag_galliots
    ]
    [
      report nobody
  ])
end

; Gets closest O enemy (enemies are Holy League) within the specified range, empty is no enemy in range
; @param self_o_ship: O ship
; @param ship_range: range to search enemies within
; @return closest enemy ship if in range, nobody otherwise
to-report get_o_ship_closest_enemy [self_o_ship ship_range]
  let is_r_range enemy_in_range self_o_ship hl_galleysr ship_range
  let is_c_range enemy_in_range self_o_ship hl_galleysc ship_range
  let is_l_range enemy_in_range self_o_ship hl_galleysl ship_range
  let is_galleass_range enemy_in_range self_o_ship hl_galleasses ship_range
  (ifelse
    is_r_range = true [
      report get_closest_item self_o_ship hl_galleysr
    ]
    is_c_range = true [
      report get_closest_item self_o_ship hl_galleysc
    ]
    is_l_range = true [
      report get_closest_item self_o_ship hl_galleysl
    ]
    is_galleass_range = true [
      report get_closest_item self_o_ship hl_galleasses
    ]
    [
      report nobody
  ])
end

; Returns boolean denoting if ship in range of enemy bread
; @param ship_item: ship searching for enemies
; @param enemy_bread: enemy bread to search
; @param acceptableRange: range of enemies to search in.
; @return true if enemy exists, false otherwise
to-report enemy_in_range [ship_item enemy_bread acceptableRange]
  let nearest_enemy get_closest_item ship_item enemy_bread
  if nearest_enemy != nobody[
    ifelse distance nearest_enemy <= acceptableRange [ report true ] [ report false ]
  ]
  report false
end

; Returns closest enemy to ship_item in enemy_bread
; @param ship_item: ship searching for enemies
; @param enemy_bread: enemy bread to search
; @return closest enemy
to-report get_closest_item [ship_item enemy_bread]
  report min-one-of enemy_bread [distance ship_item]
end


; Executes a gun attack. Adjusts status and considers hit probabilities
; @param attacking_ship: ship firing the cannon
; @param defending_ship: ship being attacked
to take_damage [attacking_ship defending_ship]
  ask defending_ship [
      set speed 0.0
    ]
  ask attacking_ship [
      set speed 0.0
    ]
  let damage [gunpowder] of attacking_ship
  ;print damage
  let hp [hit_probability] of attacking_ship
  ;print hp
  if random 100 < [hit_probability] of attacking_ship [
    ask defending_ship [
      set status ([status] of defending_ship - damage)
      ;print status
      ;print "successful gun hit"
      if status < 20 [set speed 0]
      if status < 5 [die]
    ]
  ]
end

; Executes an infrantry gun attack. Adjusts status and considers hit probabilities
; @param attacking_ship: ship attacking
; @param defending_ship: ship being attacked
to take_infantry_damage [attacking_ship defending_ship]
  ask defending_ship [
      set speed 0.0
    ]
  ask attacking_ship [
      set speed 0.0
    ]
  let damage [infantry_dmg] of attacking_ship
  ;print damage
  let hp [infantry_hit_probability] of attacking_ship
  ;print hp
  if random 100 < [infantry_hit_probability] of attacking_ship [
    ask defending_ship [
      set status ([status] of defending_ship - damage)
      set infantry_health ([infantry_health] of defending_ship - damage)
      ;print status
      ifelse allegiance = holy_league_const [
        if status < 20 [set speed 0]
        if status < 5 [die]
      ][
        if status < 20 [set speed 0]
        if status < 12 [die]
      ]
    ]
  ]
end

; Returns if a ship can move, considers ship status and if the ship has a "target enemy"
; @param ship: ship to be considered
; @return true if moveable, false otherwise
to-report can_move [ship]
  report ([status] of ship > 20) and ([target_enemy] of ship = nobody)
end

to compute_speed
  ;Loop through all ship agents and calculate speed based on weight
  ask turtles [
    if infantry_health = nobody [
      set infantry_health 0.1
    ]
    let weight_calc ((gun_power * 10) * 0.7) + (infantry_health * 0.3)
    let speed_calc -1 * ((0.1 * weight_calc) - 6) ^ 2 + 20

    if speed_calc <= 0 [
      set speed_calc 0
    ]
    let speed_calc_scaled 0.1 + ((speed_calc - 0) / (20 - 0)) * (max_speed_slider - 0.1)
    set speed speed_calc_scaled
    set weight weight_calc
    if status <= 20 [set speed 0]
    ;print speed
    ]
end

; Calculates what the current infantry dmg is based on infantry on board
to compute_infantry_dmg
  ask turtles [
    let prob random-float 1.0 ;;set probably between 0 - 1 for dmg that is added onto minimum amount
    (ifelse
      infantry_health <= 10 [
        set infantry_dmg (prob * 0.5) + 0.5
      ]
      infantry_health <= 20 [
        set infantry_dmg (prob * 0.5) + 1
      ]
      infantry_health <= 30 [
        set infantry_dmg (prob * 1) + 1.5
      ]
      infantry_health <= 40 [
        set infantry_dmg (prob * 1) + 2.5
      ]
      infantry_health <= 50 [
        set infantry_dmg (prob * 1.5) + 3.5
      ]
      infantry_health <= 60 [
        set infantry_dmg (prob * 2) + 5
      ]
      infantry_health <= 70 [
        set infantry_dmg (prob * 2) + 6
      ]
      infantry_health <= 80 [
        set infantry_dmg (prob * 1) + 8
      ]
      infantry_health <= 90 [
        set infantry_dmg (prob * 1) + 9
      ]
      infantry_health <= 100 [
        set infantry_dmg (prob * 2) + 10
      ]
      [
        set infantry_dmg (prob * 2) + 12
      ]
    )
  ]
end

; Calculates what the gunpowder_dmg is based on guns on board. Gun_power(guns on board) can be a value from 0-10. Gunpowder can range from 0 - 150
to compute_gunpowder_dmg
  ask turtles [
    let prob random-float 1.0 ;;set probably between 0 - 1 for dmg that is added onto minimum amount
    set prob random-float 1.0
    (ifelse
      gun_power = 1 [
        set gunpowder (prob * 0.25) + 0.5
      ]
      gun_power = 2 [
        set gunpowder (prob * 0.5) + 1
      ]
      gun_power = 3 [
        set gunpowder (prob * 0.5) + 1.5
      ]
      gun_power = 4 [
        set gunpowder (prob * 0.5) + 2
      ]
      gun_power = 5 [
        set gunpowder (prob * 2) + 2.5
      ]
      gun_power = 6 [
        set gunpowder (prob * 2) + 4.5
      ]
      gun_power = 7 [
        set gunpowder (prob * 2) + 5.5
      ]
      gun_power = 8 [
        set gunpowder (prob * 3) + 6.5
      ]
      gun_power = 9 [
        set gunpowder (prob * 10) + 10
      ]
      gun_power = 10 [
        set gunpowder (prob * 100) + 50
      ]
      [
        print "in 0 spot"
        set gunpowder 0
      ])
    ]

end

; Driver that sets galleass utilites based on environment
to galleass_utility
  ;;Galleasses stay put after opening volley and have no further impact
  if ticks > 30 [ask hl_galleasses [
    set speed 0
    set gun_power 0]
  ]
end

; Determines if the patch ahead has 3 or more ships. ships will turn right or left to go around it.
to patch-limitations
  ask turtles [
    let target-patch patch-ahead 1
    set turn FALSE
    let patch-occupancy 0
    set patch-occupancy patch_occupancy_utility
    (ifelse target-patch = nobody or (not any? other turtles-on target-patch) and (patch-occupancy < 2) [
      ;
    ][
      ifelse random-float 1 < 0.5 [
        lt 90 ;turn left
        forward speed ;move 1 tick
        rt 90 ;turn back heading
        set turn TRUE
      ][
      rt 90 ;turn right
      forward speed ;move 1 tick
      lt 90 ;turn back heading
      set turn TRUE
    ]
    ])
  ]
end

; Determines the number of ships in the patch ahead
to-report patch_occupancy_utility
  let target-patch patch-ahead 1
  ifelse not any? turtles-on target-patch [
    report 0
  ][
    report count turtles-on target-patch
  ]

end

; Sets the right occupancy count per patches
to update_patch_occupancy_counts
  ask patches[
    let hl_count (count hl_galleysr-here + count hl_galleysc-here + count hl_galleysc-here)
    let o_count (count o_galleysr-here + count o_galleysc-here + count o_galleysc-here)
    set patch-hl-occupancy hl_count
    set patch-o-occupancy o_count
    set patch-total-occupancy (hl_count + o_count)
  ]
end

; Sets ships nearby enemy count
to update_turtle_nearby_enemy_count
  ask turtles[
    let current-patch patch-here
    ifelse allegiance = holy_league_const [
    set enemy_count count turtles-on current-patch with [ allegiance = ottomon_empire_const]
    ][
      set enemy_count count turtles-on current-patch with [ allegiance = holy_league_const]
  ]
  ]
end

; Driver that sets board status
to update_board_status
  ask turtles [
    ifelse enemy_count > 0[
      set board_status 2
    ][
      set board_status board_status - 1
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;  setup procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  clear-all ;Clear everything

  ;Set seed so we can reproduce results
  set starting-seed new-seed
  random-seed starting-seed

  import-pcolors "images/map_without_ships.jpg"

  ; Set global constant variables
  set ottomon_empire_const "Ottoman Empire"
  set holy_league_const "Holy League"


  ;Turtle, Patches procedures
  setup-patches
  setup-turtles
  ;; below sets the patch occupancy variable to zero for each patch before proceeding.

  compute_speed
  compute_gunpowder_dmg
  compute_infantry_dmg
  reset-ticks
end

;;;set up function for patches
to setup-patches
  ;ask patches [set pcolor blue - 1]
  ;update_patch_occupancy_counts
end

;;;set up function for turtles
to setup-turtles

  ;; set up right flank holy league
  create-hl_galleysr 50 [
    set color white
    set size 11
    set shape "boat"
    set heading 90
    set gun_power 5
    set infantry_health 100
    set speed 1 ;;placeholder for speed. A separate procedure calculates each based on infantry and gun count
    set status 100 ;;set to inoperable when infantry health below 20
    set allegiance holy_league_const
    set weight 0
    set turn FALSE
    let initial_x -87
    let initial_y -147
    let x_variance 10
    let y_variance 40
    set hit_probability 60
    set infantry_hit_probability 25
    setxy one-of (range (initial_x - x_variance) (initial_x + x_variance)) one-of (range (initial_y - y_variance) (initial_y + y_variance))
  ]

  ;;set up center flank holy league
  create-hl_galleysc 96 [
    set color white
    set size 11
    set shape "boat"
    set heading 90
    set gun_power 5
    set infantry_health 100
    set speed 1 ;;placeholder for speed. A separate procedure calculates each based on infantry and gun count
    set status 100 ;;set to inoperable when infantry health below 20
    set allegiance holy_league_const
    set weight 0
    set turn FALSE
    let initial_x -77
    let initial_y -30
    let x_variance 20
    let y_variance 50
    set hit_probability 60
    set infantry_hit_probability 25
    setxy one-of (range (initial_x - x_variance) (initial_x + x_variance)) one-of (range (initial_y - y_variance) (initial_y + y_variance))
  ]

  ;;set up left flank holy league
  create-hl_galleysl 56 [
    set color white
    set size 11
    set shape "boat"
    set heading 90
    set gun_power 5
    set infantry_health 100
    set speed 1 ;;placeholder for speed. A separate procedure calculates each based on infantry and gun count
    set status 100 ;;set to inoperable when infantry health below 20
    set allegiance holy_league_const
    set weight 0
    set turn FALSE
    let initial_x -85
    let initial_y 94
    let x_variance 10
    let y_variance 40
    set hit_probability 60
    set infantry_hit_probability 25
    setxy one-of (range (initial_x - x_variance) (initial_x + x_variance)) one-of (range (initial_y - y_variance) (initial_y + y_variance))
  ]

  ;;set up galeasses
  create-hl_galleasses 6 [
    set color white + 2
    set size 16
    set shape "boat 3"
    set heading 90
    set gun_power 10
    set infantry_health 100
    set speed 0.1 ;;placeholder for speed. A separate procedure calculates each based on infantry and gun count
    set status 100 ;;set to inoperable when infantry health below 20
    set allegiance holy_league_const
    set weight 0
    set turn FALSE
    let initial_x -15
    let initial_y -13
    let x_variance 20
    let y_variance 20
    set hit_probability 15
    set infantry_hit_probability 0
    setxy one-of (range (initial_x - x_variance) (initial_x + x_variance)) one-of (range (initial_y - y_variance) (initial_y + y_variance))
  ]

  ;;set up Ottoman right flank
  create-o_galleysr 58 [
    set color green - 1
    set size 11
    set shape "boat 3"
    set heading 270
    set gun_power 2
    set infantry_health 110 ;infantry health/score.
    set speed 1 ;;placeholder for speed. A separate procedure calculates each based on infantry and gun count
    set status 100 ;;set to inoperable when infantry health below 20
    set allegiance ottomon_empire_const
    set weight 0
    set turn FALSE
    let initial_x 35
    let initial_y 115
    let x_variance 10
    let y_variance 40
    set hit_probability 25
    set infantry_hit_probability 25
    setxy one-of (range (initial_x - x_variance) (initial_x + x_variance)) one-of (range (initial_y - y_variance) (initial_y + y_variance))
  ]

  ;;set up Ottoman center flank
   create-o_galleysc 87 [
    set color green - 1
    set size 11
    set shape "boat 3"
    set heading 270
    set gun_power 2
    set infantry_health 110
    set speed 1 ;;placeholder for speed. A separate procedure calculates each based on infantry and gun count
    set status 100 ;;set to inoperable when infantry health below 20
    set allegiance ottomon_empire_const
    set weight 0
    set turn FALSE
    let initial_x 75
    let initial_y 0
    let x_variance 20
    let y_variance 50
    set hit_probability 25
    set infantry_hit_probability 25
    setxy one-of (range (initial_x - x_variance) (initial_x + x_variance)) one-of (range (initial_y - y_variance) (initial_y + y_variance))
  ]

  ;;set up Ottoman left flank
   create-o_galleysl 101 [
    set color green - 1
    set size 11
    set shape "boat 3"
    set heading 270
    set gun_power OttomanLF_Firepower
    set infantry_health 110
    set speed 1 ;;placeholder for speed. A separate procedure calculates each based on infantry and gun count
    set status 100 ;;set to inoperable when infantry health below 20
    set allegiance ottomon_empire_const
    set weight 0
    set turn FALSE
    let initial_x 90
    let initial_y -150
    let x_variance 10
    let y_variance 65
    set hit_probability 25
    set infantry_hit_probability 25
    setxy one-of (range (initial_x - x_variance) (initial_x + x_variance)) one-of (range (initial_y - y_variance) (initial_y + y_variance))
  ]

  ;;set up Ottoman galliots
  create-o_flag_galliots 5 [
    set color green
    set size 10
    set shape "boat 3"
    set heading 270
    set gun_power 1
    set infantry_health 80
    set speed 1 ;;placeholder for speed. A separate procedure calculates each based on infantry and gun count
    set status 100 ;;set to inoperable when infantry health below 20
    set allegiance ottomon_empire_const
    set weight 0
    set turn FALSE
    let initial_x 153
    let initial_y 26
    let x_variance 20
    let y_variance 20
    set hit_probability 25
    set infantry_hit_probability 40
    setxy one-of (range (initial_x - x_variance) (initial_x + x_variance)) one-of (range (initial_y - y_variance) (initial_y + y_variance))

  ]

end


to go
  let ottos count o_flag_galliots + count o_galleysl + count o_galleysc + count o_galleysr
  let hls count hl_galleasses + count hl_galleysl + count hl_galleysc + count hl_galleysr
  let ratio_hls hls / ottos
  let ratio_ottos ottos / hls
  if ratio_hls > 8 [ user-message "The Holy League has won" stop ]
  if ratio_ottos > 8 [ user-message "The Ottoman's have won" stop ]
  if ticks >= 800 [stop]
  move-turtles
  compute_speed
  ;tick-advance tick-speed
  tick
  galleass_utility ;helps stop galleass after opening and limits usage after opening ticks
  ;print "tick"
end

to move-turtles
  let hl_galley_search_range 8
  let o_galley_search_range 8

  if ticks > 60 [set hl_galley_search_range 1000]
  ;if ticks > 150 [print "new range activated"]
  if ticks > 60 [set o_galley_search_range 1000]

  ask hl_galleysl [
    let closest_enemy get_hl_ship_closest_enemy self hl_galley_search_range
    if closest_enemy != nobody [
      set heading towards closest_enemy
    ]
    let fire_on_enemy get_hl_ship_closest_enemy self 10
    if fire_on_enemy != nobody[
      take_damage self fire_on_enemy
    ]
    let infantry_on_enemy get_hl_ship_closest_enemy self 1
    if fire_on_enemy != nobody[
        take_infantry_damage self fire_on_enemy
    ]
  ]
  ask o_galleysr [
    let closest_enemy get_o_ship_closest_enemy self o_galley_search_range
    if closest_enemy != nobody [
      set heading towards closest_enemy
    ]
    let fire_on_enemy get_o_ship_closest_enemy self 10
    if fire_on_enemy != nobody[
      take_damage self fire_on_enemy
    ]
    let infantry_on_enemy get_hl_ship_closest_enemy self 1
    if fire_on_enemy != nobody[
        take_infantry_damage self fire_on_enemy
    ]
  ]
  ask hl_galleysc [
    let closest_enemy get_hl_ship_closest_enemy self hl_galley_search_range
    if closest_enemy != nobody [
      set heading towards closest_enemy
    ]

    let fire_on_enemy get_hl_ship_closest_enemy self 10
    if fire_on_enemy != nobody[
        take_damage self fire_on_enemy
      ]
    let infantry_on_enemy get_hl_ship_closest_enemy self 1
    if fire_on_enemy != nobody[
        take_infantry_damage self fire_on_enemy
    ]
  ]
  ask o_galleysc [
    let closest_enemy get_o_ship_closest_enemy self o_galley_search_range
    if closest_enemy != nobody [
      set heading towards closest_enemy
    ]
    let fire_on_enemy get_o_ship_closest_enemy self 10
    if fire_on_enemy != nobody[
      take_damage self fire_on_enemy
    ]
    let infantry_on_enemy get_hl_ship_closest_enemy self 1
    if fire_on_enemy != nobody[
      take_infantry_damage self fire_on_enemy
    ]
  ]
  ask hl_galleysr [
    let closest_enemy get_hl_ship_closest_enemy self hl_galley_search_range
    if closest_enemy != nobody [
      set heading towards closest_enemy
    ]
    let fire_on_enemy get_hl_ship_closest_enemy self 10
    if fire_on_enemy != nobody[
       take_damage self fire_on_enemy
      ;print gunpowder
    ]
    let infantry_on_enemy get_hl_ship_closest_enemy self 1
    if fire_on_enemy != nobody[
      take_infantry_damage self fire_on_enemy
    ]
  ]
  ask o_galleysl [
    let closest_enemy get_o_ship_closest_enemy self o_galley_search_range
    if closest_enemy != nobody [
      set heading towards closest_enemy
    ]
    let fire_on_enemy get_o_ship_closest_enemy self 10
    if fire_on_enemy != nobody[
      take_damage self fire_on_enemy
    ]
    let infantry_on_enemy get_hl_ship_closest_enemy self 1
    if fire_on_enemy != nobody[
        take_infantry_damage self fire_on_enemy
    ]
  ]

   ask hl_galleasses [
    let closest_enemy get_hl_ship_closest_enemy self hl_galley_search_range
    if closest_enemy != nobody [
      set heading towards closest_enemy
      if ticks > 15 [set heading 90] ;;Galleass only battle in beginning
    ]
    let fire_on_enemy get_hl_ship_closest_enemy self 10
    if fire_on_enemy != nobody[
      take_damage self fire_on_enemy
    ]
    let infantry_on_enemy get_hl_ship_closest_enemy self 1
    if fire_on_enemy != nobody[
        take_infantry_damage self fire_on_enemy

    ]
  ]

   ask o_flag_galliots [
    let closest_enemy get_o_ship_closest_enemy self o_galley_search_range
    if closest_enemy != nobody [
      set heading towards closest_enemy
    ]
    let fire_on_enemy get_o_ship_closest_enemy self 10
    if fire_on_enemy != nobody[
      take_damage self fire_on_enemy
    ]
    let infantry_on_enemy get_o_ship_closest_enemy self 1
    if fire_on_enemy != nobody[
        take_infantry_damage self fire_on_enemy

    ]
  ]

  patch-limitations ;;this sets patch limitatons so turtles move around a space that has atleast 5 turtles in it
  ;update_patch_occupancy_counts ;; counts types of ships in each patch

  ask turtles [
    ;;;This code modifies the timing of the seaside flank. They pause until certian number of ticks is reached.
    ;;;"OttomanTiming" is defined in the slider on the interface page and referenced here. Only impacts the Ottoman left flank breed
    ifelse ticks <= OttomanTiming and member? self turtles with [breed = o_galleysl][
      ;Do nothing
    ]
    [
    ;;Agents move only if operable.
    if status >= 5[
      if pcolor >= 98 [
          if turn = FALSE [
            if board_status = 0 [
              forward speed
            ]
          ]
      ]
      if ticks >= 350 [
          ;print speed
        ]
    ]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
189
30
999
949
-1
-1
2.0
1
10
1
1
1
0
0
0
1
-200
200
-227
227
1
1
1
ticks
30.0

BUTTON
1014
93
1079
127
Setup
Setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1012
135
1135
171
Run Model
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

SLIDER
1008
182
1180
215
OttomanTiming
OttomanTiming
1
150
6.0
1
1
NIL
HORIZONTAL

TEXTBOX
1193
185
1343
213
Adjust to modify entrace of Ottoam Seaside  Flank
11
0.0
1

SLIDER
1557
135
1729
168
InfantryHitProb
InfantryHitProb
0
100
29.0
1
1
NIL
HORIZONTAL

SLIDER
1556
210
1728
243
GunHitProb_Galley
GunHitProb_Galley
0
100
25.0
1
1
NIL
HORIZONTAL

SLIDER
1557
173
1729
206
GunHitProb_Galleass
GunHitProb_Galleass
0
100
33.0
1
1
NIL
HORIZONTAL

TEXTBOX
1566
107
1716
125
Have not assigned these yet
11
0.0
1

SLIDER
1010
225
1182
258
max_speed_slider
max_speed_slider
0
2
1.2
0.05
1
NIL
HORIZONTAL

MONITOR
76
30
185
75
NIL
count hl_galleysr
17
1
11

MONITOR
74
122
182
167
NIL
count hl_galleysl
17
1
11

MONITOR
72
169
183
214
NIL
count hl_galleysc
17
1
11

MONITOR
74
216
180
261
NIL
count o_galleysr
17
1
11

MONITOR
75
263
179
308
NIL
count o_galleysl
17
1
11

MONITOR
73
312
181
357
NIL
count o_galleysc
17
1
11

MONITOR
74
76
186
121
NIL
count hl_galleasses
17
1
11

MONITOR
68
363
185
408
NIL
count o_flag_galliots
17
1
11

MONITOR
69
411
184
456
Ottomans
count o_flag_galliots + count o_galleysl + count o_galleysc + count o_galleysr
17
1
11

MONITOR
66
459
183
504
Holy League
count hl_galleasses + count hl_galleysl + count hl_galleysc + count hl_galleysr
17
1
11

PLOT
1009
330
1209
480
plot 1
Time
Deaths
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Holy League" 1.0 0 -16777216 true "" "plot count hl_galleasses + count hl_galleysl + count hl_galleysc + count hl_galleysr"
"Ottos" 1.0 0 -7500403 true "" "plot count o_flag_galliots + count o_galleysl + count o_galleysc + count o_galleysr"

TEXTBOX
1195
225
1362
267
Adjusts the scale of the speed parameters by setting max number
11
0.0
1

SLIDER
1009
273
1181
306
OttomanLF_Firepower
OttomanLF_Firepower
1
10
4.0
1
1
NIL
HORIZONTAL

TEXTBOX
1194
279
1382
307
Adjust the Ottoman Seaside Flank Firepower rating
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

boat
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

boat 3
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 37 172 45 188 59 202 79 217 109 220 130 218 147 204 156 158 156 161 142 170 123 170 102 169 88 165 62
Polygon -7500403 true true 149 66 142 78 139 96 141 111 146 139 148 147 110 147 113 131 118 106 126 71

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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
