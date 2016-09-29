module Main exposing (..)

import Html exposing (Html, div, text)
import Html.App
import Keyboard exposing (KeyCode)
import AnimationFrame
import Collage exposing (..)
import Color exposing (..)
import Element exposing (..)
import Time exposing (Time, second)


-- MODEL


type alias Entity =
    { x : Float, y : Float, vx : Float, vy : Float }


type alias Player =
    Entity


playerSpeed : Float
playerSpeed = 4


type alias Enemy =
    Entity


type alias Bullet =
    Entity


type KeyInput
    = Up
    | Down
    | Left
    | Right
    | ShootKey


type alias KeyState =
    { up : Bool, down : Bool, left : Bool, right : Bool }


initKeys : KeyState
initKeys =
    { up = False, down = False, left = False, right = False }


type alias Model =
    { player : Player, enemies : List Enemy, bullets : List Bullet, keys : KeyState }


player : Collage.Shape
player =
    Collage.rect 40 40


bullet : Collage.Shape
bullet =
    Collage.rect 10 10


init : ( Model, Cmd Msg )
init =
    ( { player = { x = 0, y = 0, vx = 0, vy = 0 }
      , enemies = []
      , bullets = []
      , keys = initKeys
      }
    , Cmd.none
    )



-- MESSAGES


type KeyDir
    = KeyUp
    | KeyDown


type Msg
    = KeyMsg KeyDir KeyInput
    | TimeTick Time
    | FrameTick Float
    | SpawnEnemy
    | Shoot
    | NoOp



-- VIEW


drawEntity : Entity -> Collage.Form -> Collage.Form
drawEntity e s =
    s |> move ( e.x, e.y )


drawBullet : Bullet -> Collage.Form
drawBullet b =
    Collage.rect 10 10 |> filled Color.red |> (drawEntity b)


drawPlayer : Player -> Collage.Form
drawPlayer p =
    Collage.rect 40 40 |> filled Color.blue |> (drawEntity p)


drawEnemy : Enemy -> Collage.Form
drawEnemy e =
    Collage.rect 40 40 |> filled Color.red |> (drawEntity e)


view : Model -> Html msg
view model =
    Collage.collage
        600
        600
        (List.concat
            [ [ drawPlayer model.player
              ]
            , List.map drawBullet model.bullets
            , List.map drawEnemy model.enemies
            ]
        )
        |> toHtml



-- UPDATE


keyCodeToInput : KeyCode -> Maybe KeyInput
keyCodeToInput code =
    case code of
        37 ->
            Just Left

        38 ->
            Just Up

        39 ->
            Just Right

        40 ->
            Just Down

        32 ->
            Just ShootKey

        _ ->
            Nothing


updateKeyState : KeyDir -> KeyInput -> KeyState -> KeyState
updateKeyState dir input keys =
    let
        dirToBool dir =
            case dir of
                KeyUp ->
                    False

                KeyDown ->
                    True
    in
        case input of
            Left ->
                { keys | left = dirToBool dir }

            Right ->
                { keys | right = dirToBool dir }

            Up ->
                { keys | up = dirToBool dir }

            Down ->
                { keys | down = dirToBool dir }

            _ -> keys


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        KeyMsg dir input ->
            let
                keys' =
                    updateKeyState dir input model.keys

                model' =
                    { model | keys = keys' }
                        |> setPlayerVel
            in
                ( model', Cmd.none )

        FrameTick dt ->
            ( step dt model, Cmd.none )

        TimeTick t ->
            ( model, Cmd.none )

        SpawnEnemy ->
            ( { model | enemies = spawnEnemy :: model.enemies }, Cmd.none )

        Shoot ->
            ( { model | bullets = shoot model.player :: model.bullets }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


step : Float -> Model -> Model
step dt model =
    let
        p' =
            updatePlayer dt model.player

        es' =
            List.map (updateEnemy dt) model.enemies

        bs' =
            List.map (updateEntity dt) model.bullets
    in
        { model | player = p', enemies = es', bullets = bs' }


spawnEnemy : Enemy
spawnEnemy =
    { x = 0, y = 200, vx = 0, vy = -2 }


shoot : Player -> Bullet
shoot p =
    { x = p.x, y = p.y, vx = 0, vy = 5 }


setPlayerVel : Model -> Model
setPlayerVel model =
    let
        keys =
            model.keys

        p =
            model.player

        vx =
            if keys.left then
                -playerSpeed
            else if keys.right then
                playerSpeed
            else
                0

        vy =
            if keys.up then
                playerSpeed
            else if keys.down then
                -playerSpeed
            else
                0

        p' =
            { p | vx = vx, vy = vy }
    in
        { model | player = p' }


updateEntity : Float -> Entity -> Entity
updateEntity dt entity =
    { entity | x = entity.x + entity.vx, y = entity.y + entity.vy }


updatePlayer : Float -> Player -> Player
updatePlayer =
    updateEntity

updateEnemy : Float -> Enemy -> Enemy
updateEnemy =
    updateEntity


updateBullet : Float -> Bullet -> Bullet
updateBullet = updateEntity


-- SUBSCRIPTIONS


keyCodeToMsg : KeyDir -> KeyCode -> Msg
keyCodeToMsg dir kc =
    case keyCodeToInput kc of
        Nothing ->
            NoOp

        Just ShootKey ->
            Shoot

        Just key ->
            KeyMsg dir key


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Keyboard.downs (keyCodeToMsg KeyDown)
        , Keyboard.ups (keyCodeToMsg KeyUp)
        , AnimationFrame.diffs FrameTick
        , Time.every second (\_ -> SpawnEnemy)
        ]



-- MAIN


main : Program Never
main =
    Html.App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }