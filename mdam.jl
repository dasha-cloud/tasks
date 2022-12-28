using HorizonSideRobots
import HorizonSideRobots.move!

# ФУНКЦИИ ДЛЯ ЗАДАЧ

function motion!(r, side, num_steps) # движение на n шагов в заданную сторону
    for i in 1:num_steps
        move!(r, side)
    end
end


function move_until_border!(r, side) # двигается до перегородки
    num_steps = 0
    while !isborder(r, side)
        num_steps += 1
        move!(r, side)
    end
    return num_steps
end


function inverse_side(side) # меняет сторону на противоположную
    side_inv = HorizonSide((Int(side) + 2) % 4)
    return side_inv
end


function putmarkers_until_border!(r, side) # ставит маркеры до перегородки
    num_steps = 0
    while !isborder(r, side) 
        move!(r, side)
        putmarker!(r)
        num_steps += 1
    end 
    return num_steps
end


function steps_to_corner!(r)  # перемещает робота в левый нижний угол и возвращает количество шагов  
    n1 = move_until_border!(r, West)
    n2 = move_until_border!(r, Sud)
    steps=[n1,n2]
    return steps
end


function come_to_back!(r, steps_back) # перемещает робота в исходное положение
    for (i, side) in enumerate((Ost, Nord))
        motion!(r, side, steps_back[i])
    end
end


function putmarkers_until_border2!(r, sides) # функция putmarkers_until_border! для направления из 2 сторон
    num_steps = 0
    while !isborder(r, sides[1]) && !isborder(r, sides[2])
        num_steps += 1
        move!(r, sides) # не встроена, отдельно написана ниже
        putmarker!(r)
    end
    return num_steps
end


function motion2!(r, sides, num_steps) # функция motion! для напрвления из 2 сторон
    for i in 1:num_steps
        move!(r, sides) # не встроена, отдельно написана ниже
    end
end


function move!(r, sides) # функция move! для направления из 2 сторон
    for side in sides
        move!(r, side)
    end
end


function inverse_side2(sides) # меняет на противопложные 2 стороны
    new_sides = (inverse_side(sides[1]), inverse_side(sides[2]))
    return new_sides
end





#ЗАДАЧИ

# номер 1

function mark_krest!(r)
    for side in (HorizonSide(i) for i in 0:3)
        num_steps = putmarkers_until_border!(r, side)
        motion!(r, inverse_side(side), num_steps)
    end
    putmarker!(r)
end


# номер 2

function mark_perimetr!(r)
    n=steps_to_corner!(r)
    for side in (Nord, Ost, Sud, West)
        putmarkers_until_border!(r, side)
    end
    come_to_back!(r,n)
end


# номер 3

function mark_all!(r)
    steps_back = steps_to_corner!(r)
    putmarker!(r)
    while !isborder(r, Ost)
        putmarkers_until_border!(r,Nord)
        move!(r, Ost)
        putmarker!(r)
        putmarkers_until_border!(r, Sud)
    end
    steps_to_corner!(r)
    come_to_back!(r, steps_back)
end


# номер 4

function mark_X!(r)
    sides = (Nord, Ost, Sud, West)
    for i in 1:4
        side_1 = sides[i]
        side_2 = sides[i % 4 + 1]
        direction = (side_1, side_2)
        num_steps = putmarkers_until_border2!(r, direction)
        motion2!(r, inverse_side2(direction), num_steps)
    end
    putmarker!(r)
end


###

function move_if_possible!(r, side)::Bool  # возвращает есть перегородка или нет
    if !isborder(r, side)
        move!(r, side)
        return true
    end
    return false
end

function steps_to_corner_with_borders!(r)::Vector{Tuple{HorizonSide, Int}} # например[(West, 7), (Sud, 4), (West, 4), (Sud, 0)]
    steps_back = []
    while !(isborder(r, West) && isborder(r, Sud))   # пока нет перегородки и на западе, и на юге (пока не нижний левый угол) 
        steps1 = move_until_border!(r, West)
        steps2 = move_until_border!(r, Sud)
        push!(steps_back, (West, steps1)) # добавляем в массив число шагов с направлением
        push!(steps_back, (Sud, steps2))
    end
    return steps_back
end

function inversed_route(route::Vector{Tuple{HorizonSide, Int}})::Vector{Tuple{HorizonSide, Int}}
    in_route = []
    for step in route
        in_step = (inverse_side(step[1]), step[2])
        push!(in_route, in_step)
    end
    reverse!(in_route)
    return in_route
end

function make_route!(r, path::Vector{Tuple{HorizonSide, Int}})
    for step in path
        motion2!(r, step[1], step[2])
    end
end

function come_to_back_with_borders!(r, route::Vector{Tuple{HorizonSide, Int}}) # возвращает робота в исходную позицию
    in_route = inversed_route(route)
    make_route!(r, in_route)
end


# номер 5

function mark_inside_rect!(r)

    steps_back = steps_to_corner_with_borders!(r)
    
    while isborder(r, Sud) && !isborder(r, Ost)
        move_until_border!(r, Nord)
        move!(r, Ost)
        while !isborder(r, Ost) && move_if_possible!(r, Sud) end
    end

    for sides in [(Sud, Ost), (Ost, Nord), (Nord, West), (West, Sud)]
        move_side, border_side = sides
        while isborder(r, border_side)
            putmarker!(r)
            move!(r, move_side)
        end
        putmarker!(r)
        move!(r, border_side)
    end

    steps_to_corner_with_borders!(r)
    for side in (Nord, Ost, Sud, West)
        putmarkers_until_border!(r, side)
    end
    come_to_back_with_borders!(r,steps_back)
end



# номер 6

# 6а
function mark_perimetr_with_borders!(r) 
    steps_back = steps_to_corner_with_borders!(r)
    mark_perimetr!(r)
    come_to_back_with_borders!(r, steps_back)
end


# 6b
function mark_four_cells!(r)  
    steps_back = steps_to_corner_with_borders!(r)
    sud_steps = 0
    west_steps = 0
    for step in steps_back
        if step[1] == Sud
            sud_steps += step[2]
        else
            west_steps += step[2]
        end
    end

    motion2!(r, Ost, west_steps)
    putmarker!(r)
    move_until_border!(r, Ost)
    motion2!(r, Nord, sud_steps)
    putmarker!(r)
    steps_to_corner_with_borders!(r)

    motion2!(r, Nord, sud_steps)
    putmarker!(r)
    move_until_border!(r, Nord)
    motion2!(r, Ost, west_steps)
    putmarker!(r)
    steps_to_corner_with_borders!(r)

    come_to_back_with_borders!(r, steps_back)
end


# номер 7

function passage_find!(r, side) # Nord 
    num_steps = 1
    move_side = West
    while isborder(r, side)
        motion!(r, move_side, num_steps)
        num_steps += 1
        move_side = inverse_side(move_side)
    end
end



# номер 8

function move_if_not_marker!(r, side)::Bool

    if !ismarker(r)
        move!(r, side)
        return false
    end

    return true
end

function moves_if_not_marker!(r, side, num_steps)::Bool

    for i in 1:num_steps
        if move_if_not_marker!(r, side)
            return true
        end
    end

    return false
end

function next_side(side)  # перпендикулярная к side сторона
    return HorizonSide( (Int(side) + 1 ) % 4 )
end


function move_snake_until_marker!(r)  
    num_steps = 1
    side = Ost
    count = 1
    while true   # бесконечный цикл, заканчивается, когда срабатывает return

        if moves_if_not_marker!(r, side, num_steps)
            return
        end 

        side = next_side(side)

        if count % 2 == 0
            num_steps += 1
        end

        count += 1
    end
end

# номер 8 упрощенный
        
function find_marker!(r)
    max_steps = 1
    side = Ost
    while !ismarker(r)
        find_marker_along!(r, side, max_steps)
        side = next_side(side)
        find_marker_along!(r, side, max_steps)
        max_steps += 1
        side = next_side(side)
    end
end
function find_marker_along!(r, side, max_steps)
    num_steps = 0
    while num_steps < max_steps && !ismarker(r)
        move!(r, side)
        num_steps += 1
    end
end       


# номер 9
        
function mark_chess!(r)
    
    steps_back = steps_to_corner!(r)
    marker = (steps_back[1] + steps_back[2]) % 2 == 0 # функция с данным условием
    steps_to_ost = move_until_border!(r, Ost)
    move_until_border!(r, West)
    last_side = steps_to_ost % 2 == 1 ? Sud : Nord # проверка на четность числа клеток

    side = Nord

    while !isborder(r, Ost)
        
        while !isborder(r, side)
            if marker
                putmarker!(r)
            end

            move!(r, side)
            marker = !marker
        end

        if marker
            putmarker!(r)
        end

        move!(r, Ost)
        marker = !marker
        
        side = inverse_side(side)
    end

    while !isborder(r, last_side)
        
        while !isborder(r, side)
            if marker
                putmarker!(r)
            end

            move!(r, side)
            marker = !marker
        end

        if marker
            putmarker!(r)
        end

    end

    steps_to_corner!(r)
    come_to_back!(r, steps_back)
end



# номер 11

function count_horizontal_borders!(r)
    steps_back = steps_to_corner!(r)
    side = Ost
    num_borders = num_horizontal_borders!(r, side)
    while !isborder(r, Nord)
        move!(r, Nord)
        side = inverse_side(side)
        num_borders += num_horizontal_borders!(r, side)
    end
    steps_to_corner!(r)
    come_to_back!(r, steps_back)
    return num_borders
end
function num_horizontal_borders!(r, side)
    num_borders = 0
    cur_border = 0 # в направлении Nord внутренней перегородки нет 
    while !isborder(r, side)
        move!(r, side)
        if cur_border == 0
            if isborder(r, Nord) == true
                cur_border = 1 # обнаружено начало перегородки
            end
        else 
            if isborder(r, Nord) == false
                cur_border = 0
                num_borders += 1
            end
        end
    end
    return num_borders
end



# номер 12

function count_horizontal_borders2!(r)
    steps_back = steps_to_corner!(r)
    side = Ost
    num_borders = num_horizontal_borders2!(r, side)
    while !isborder(r, Nord)
        move!(r, Nord)
        side = inverse_side(side)
        num_borders += num_horizontal_borders2!(r, side)
    end
    steps_to_corner!(r)
    come_to_back!(r, steps_back)
    return num_borders
end


function num_horizontal_borders2!(r, side)
    num_borders = 0
    cur_border = 0 # в направлении Nord внутренней перегородки нет 
    razruv = 0
    while !isborder(r, side)
        move!(r, side)
        if cur_border == 0 
            if isborder(r, Nord) == true
                cur_border = 1 # обнаружено начало перегородки
                razruv=0
            end
        else 
            if isborder(r, Nord) == false
                if razruv == 0
                    cur_border = 1
                    razruv += 1
                else                    
                    cur_border = 0
                    if razruv==1
                        num_borders += 1
                    end
                    razruv+=1
                end
            end
        end
        if cur_border == 1 && razruv == 1  # для одной перегородки с несколькими разрывами в одну клетку
            if isborder(r, Nord) == true
                cur_border = 1 
                razruv=0
            end
        end
    end    
    if !isborder(r,Nord) && razruv == 1
        num_borders += 1
    end
    return num_borders
end


# номер 15

function passage_find_obob!(r, side_border)  # Nord
    num_steps = 1
    move_side = West

    while isborder(r, side_border)
        for i in 1:num_steps
            shatl!( i -> !isborder(r, side_border), r, move_side)
        end
        move_side = inverse_side(move_side)
        num_steps += 1
    end
end


function shatl!(stop_condition::Function, r, side)
    if !stop_condition(side)
        move!(r, side)
    end
end



# номер 16

function where_marker!(r)
    stp = (side) -> ismarker(r)  # stop_condition , ( если есть маркер )
    spiral!(stp, r)  
end

function along!(stop_condition, r, side, max_steps)  
    num_steps = 0
    while !stop_condition(side) && num_steps < max_steps
        move!(r, side)
        num_steps += 1
    end
    return num_steps
end

# делает не более чем max_steps шагов в заданном направлении, до выполнения условии останова stop_condition(), и возвращает число фактически сделанных шагов
# stop_condition - условие останова - функция без аргументов, возвращающая логическое значение

function spiral!(stop_condition::Function, r)
    num_steps = 1
    side = Ost
    while !stop_condition(side)  # нет маркера
        along!(stop_condition, r, side, num_steps)  
        side = next_side(side)  # из 8 задачи
        along!(stop_condition, r, side, num_steps)
        side = next_side(side)
        num_steps +=1
    end
end



# номер 18

function recursive_to_border!(r, side)
    if !isborder(r, side)
        move!(r, side)
        recursive_to_border!(r, side)
    end
end


# номер 19

function recursive_to_border_and_back!(r, side, num_steps = 0)
    if !isborder(r, side)
        move!(r, side)
        num_steps += 1
        recursive_to_border_and_back!(r, side, num_steps)
    else
        putmarker!(r)
        along!(r, inverse_side(side), num_steps)
    end
end

function along!(r, side, num_steps)
    num = 0
    while !isborder(r, side) && num < num_steps
        move!(r, side)
        num += 1
    end
end


# номер 20

function sosed_cell_through_border!(r, side, num_steps = 0)
    if isborder(r, side)
        move!(r, next_side(side))
        num_steps += 1
        sosed_cell_through_border!(r, side, num_steps)
    else
        move!(r, side)
        along!(r, inverse_side(next_side(side)), num_steps)
    end
end


# номер 25

function mark_chess_rec!(r, side, to_mark = true)
    if to_mark
        putmarker!(r)
    end

    if !isborder(r, side)
        move!(r, side)
        to_mark = !to_mark
        mark_chess_rec!(r, side, to_mark)
    end
end

#  25а 
function mark_chess_1!(r::Robot, side::HorizonSide)
    mark_chess_rec!(r, side)
end

#  25б
function mark_chess_2!(r)
    mark_chess_rec!(r, side, false)
end
        
       

# номер 26

# 26а 

function n_fibbonachi(n)::Int
    if n == 1 || n == 2
        return 1
    end
    a = 1
    b = 1
    for i in 3:n
        c = a + b
        a, b = b, c
    end
    return b
end

# 26б

function n_fibbonachi_rec(n)::Int
    if n == 1 || n == 2
        return 1
    end

    return n_fibbonachi_rec(n-1) + n_fibbonachi_rec(n - 2)
end

        
# номер 21
        
function dobledist!(r, side)
    if !isborder(r,side)
        move!(r,side)
        doubledist!(r, side)
    else
        move!(r,inverse_side(side))
        move!(r, inverse_side(side))
    end
end
            
          #структура робота
            mutable struct CoordRobot
                r::Robot
                coord.x::Int
                coord.y::Int
            end
            r = Robot(animate = true)
            coordRobot = CoordRobot(r,0,0)
