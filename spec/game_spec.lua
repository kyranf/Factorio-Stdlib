require "spec/setup/defines"
require "stdlib/utils/table"
local Game = require "stdlib/game"

describe("Game Spec",
    function()

        setup(
            function()
                -- _G.serpent = require("serpent")
            end
        )

        before_each(
            function()
                --Set __self and valid on __index when forces are added to game
                local _mt = {
                    __newindex = function (t, k, v)
                        rawset(t, k, v)
                        setmetatable(t[k], {__index = {valid = true, __self = "userdata", }})
                    end
                }
                _G.game = { players = { }, connected_players = { }, forces = { } }
                _G.global = { players = { }, forces = { }}

                setmetatable(game.players, _mt)
                setmetatable(global.players, _mt)
                setmetatable(game.forces, _mt)
                setmetatable(global.forces, _mt)
            end
        )

        it("Game.print_all should message no players",
            function()
                game.connected_players = table.filter(game.players, function(p) return p.connected end)
                Game.print_all("Hello World")
            end
        )

        it("Game.print_all should message all connected players",
            function()
                for _ = 1, 10 do
                    table.insert(game.players, { valid = true, connected = true, print = spy.new(function() end) })
                end
                game.connected_players = table.filter(game.players, function(p) return p.connected end)

                assert.same(10, Game.print_all("Hello World"))
                for i = 1, 10 do
                    assert.spy(game.connected_players[i].print).was_called_with("Hello World")
                end
            end
        )

        it("Game.print_all should message connected players on nauvis surface",
            function()
                for i = 1, 10 do
                    if i == 5 or i == 7 then
                        table.insert(game.players, { surface = { name = "nauvis" }, valid = true, connected = true, print = spy.new(function() end) })
                    else
                        table.insert(game.players, { surface = { name = "other" }, valid = true, connected = true, print = spy.new(function() end) })
                    end
                end
                game.connected_players = table.filter(game.players, function(p) return p.connected end)

                assert.same(2, Game.print_all("Hello World", function(p) return p.surface.name == "nauvis" end))
                --assert.same(2, Game.print_all({ name = "nauvis" }, "Hello World"))
                --assert.same(2, Game.print_surface("nauvis", "Hello World"))
                assert.spy(game.players[5].print).was_called_with("Hello World")
                assert.spy(game.players[7].print).was_called_with("Hello World")
            end
        )

        it("Game.print_all should message connected players on player force",
            function()
                for i = 1, 10 do
                    if i == 5 or i == 7 then
                        table.insert(game.players, { force = { name = "enemy" }, valid = true, connected = true, print = spy.new(function() end) })
                    else
                        table.insert(game.players, { force = { name = "player" }, valid = true, connected = true, print = spy.new(function() end) })
                    end
                end
                game.connected_players = table.filter(game.players, function(p) return p.connected end)

                assert.same(8, Game.print_all("Hello World", function(p) return p.force.name == "player" end))
                --assert.same(8, Game.print_force("player", "Hello World"))
                assert.spy(game.players[5].print).was_not_called_with("Hello World")
                assert.spy(game.players[7].print).was_not_called_with("Hello World")
            end
        )

        it("Game.fail_if_missing should return false if var is true or truthy",
            function()
                assert.is_false(Game.fail_if_missing(true, nil))
                assert.is_false(Game.fail_if_missing({}, nil))
                assert.is_false(Game.fail_if_missing(0, nil))
                assert.is_false(Game.fail_if_missing(0.123, nil))
                assert.is_false(Game.fail_if_missing("", nil))
            end
        )

        it("Game.fail_if_missing should error with Missing value as a message when var is false or nil",
            function()
                assert.has_error(function() Game.fail_if_missing(false, nil) end, "Missing value")
                assert.has_error(function() Game.fail_if_missing(nil, nil) end, "Missing value")
            end
        )

        it("Game.fail_if_missing should error with given msg when var is false or nil",
            function()
                assert.has_error(function() Game.fail_if_missing(false, "error1") end, "error1")
                assert.has_error(function() Game.fail_if_missing(nil, "error2") end, "error2")
            end
        )

        it("Game.get_force should return mixed if mixed is table & userdata and mixed.valid is not nil",
            function()
                local force_names = {"ForceOne", "ForceTwo", "ForceThree"}
                for _, force_name in ipairs(force_names) do
                    game.forces[force_name] = { index = force_name, name = force_name}
                end
                for _, force in pairs(game.forces) do
                    assert.equal(force, Game.get_force(force))
                    assert.same(force, Game.get_force(force))
                end
            end
        )

        it("Game.get_force should return game.forces[mixed.force] if mixed is table, not userdata, and mixed.force is string (force name)",
            function()
                local force_names = {"ForceOne", "ForceTwo", "ForceThree"}
                for _, force_name in ipairs(force_names) do
                    game.forces[force_name] = { index = force_name, force = force_name}
                    game.forces[force_name].__self = false
                end
                for _, force in pairs(game.forces) do
                    assert.equal(force, Game.get_force(force))
                    assert.same(force, Game.get_force(force))
                end
            end
        )

        it("Game.get_force should return game.forces[mixed] if mixed is string (force name)",
            function()
                local force_names = {"ForceOne", "ForceTwo", "ForceThree"}
                for _, force_name in ipairs(force_names) do
                    game.forces[force_name] = { index = force_name, force = force_name}
                    assert.equal(game.forces[force_name], Game.get_force(force_name))
                    assert.same(game.forces[force_name], Game.get_force(force_name))
                end
            end
        )

        it("Game.get_force should return nil if mixed is table and not userdata, but mixed.force is nil or false",
            function()
                local force_names = {"ForceOne", "ForceTwo", "ForceThree"}
                for _, force_name in ipairs(force_names) do
                    game.forces[force_name] = { index = force_name, force = false}
                    game.forces[force_name].__self = false
                    assert.is_nil(Game.get_force(game.forces[force_name]))
                    game.forces[force_name].force = nil
                    assert.is_nil(Game.get_force(game.forces[force_name]))
                end
            end
        )

        it("Game.get_force should return nil if mixed is neither table nor string",
            function()
                assert.is_nil(Game.get_force(false))
                assert.is_nil(Game.get_force(nil))
                assert.is_nil(Game.get_force(true))
                assert.is_nil(Game.get_force(0))
                assert.is_nil(Game.get_force({}))
                assert.is_nil(Game.get_force("trust the force"))
            end
        )

        it("Game.get_force should return false",
            function()
                assert.is_false(Game.get_force({index = "Force", force = "Force", __self = true, valid = false}))
                game.forces["Force"] = { index = "Force", force = "Force", __self = true, valid = false }
                assert.is_false(Game.get_force("Force"))
            end
        )

        it("Game.get_player should return mixed back if mixed is a table and a userdata and mixed.valid is true",
            function()
                local player_names = {"ForceOne", "ForceTwo", "ForceThree"}
                for player_index, player_name in ipairs(player_names) do
                    game.players[player_index] = { player_index = player_index, name = player_name}
                end
                for _, player in ipairs(game.players) do
                    assert.equal(player, Game.get_player(player))
                    assert.same(player, Game.get_player(player))
                end
            end
        )

        it("Game.get_player should return game.players[mixed.player_index] if mixed is a table and not a userdata and mixed.player_index exists",
            function()
                local player_names = {"ForceOne", "ForceTwo", "ForceThree"}
                for player_index, player_name in ipairs(player_names) do
                    game.players[player_index] = { player_index = player_index, name = player_name}
                    game.players[player_index].__self = false
                end
                for _, player in ipairs(game.players) do
                    assert.equal(player, Game.get_player(player))
                    assert.same(player, Game.get_player(player))
                end
            end
        )

        it("Game.get_player should return game.players[mixed] if mixed is not a table and is neither false nor nil and game.players[mixed].valid == true",
            function()
                local player_names = {"ForceOne", "ForceTwo", "ForceThree"}
                for player_index, player_name in ipairs(player_names) do
                    game.players[player_index] = { player_index = player_index, name = player_name}
                end
                for player_index in ipairs(player_names) do
                    assert.equal(game.players[player_index], Game.get_player(player_index))
                    assert.same(game.players[player_index], Game.get_player(player_index))
                end
            end
        )

        it("Game.get_player should return nil if mixed is false or nil",
            function()
                assert.is_nil(Game.get_player(nil))
                assert.is_nil(Game.get_player(false))
            end
        )

        it("Game.get_player should return false if mixed is table & userdata but mixed.valid == false",
            function()
                local player_names = {"ForceOne", "ForceTwo", "ForceThree"}
                for player_index, player_name in ipairs(player_names) do
                    game.players[player_index] = { player_index = player_index, name = player_name, valid = false}
                end
                for _, player in ipairs(game.players) do
                    assert.is_false(Game.get_player(player))
                end
            end
        )

        it("Game.get_player should return nil if mixed is table, not userdata, and mixed.player_index is nil",
            function()
                local player_names = {"ForceOne", "ForceTwo", "ForceThree"}
                for player_index, player_name in ipairs(player_names) do
                    game.players[player_index] = { player_index = nil, name = player_name, valid = false, __self = false}
                end
                for _, player in ipairs(game.players) do
                    assert.is_nil(Game.get_player(player))
                end
            end
        )

        it("Game.get_player should return false if mixed is table, not userdata, mixed.player_index exists, but game.players[mixed.player_index].valid == false",
            function()
                local player_names = {"ForceOne", "ForceTwo", "ForceThree"}
                for player_index, player_name in ipairs(player_names) do
                    game.players[player_index] = { player_index = player_index, name = player_name, valid = false, __self = false}
                end
                for _, player in ipairs(game.players) do
                    assert.is_false(Game.get_player(player))
                end
            end
        )

        it("Game.get_player should return false if mixed is not a table and not nil and not false and game.players[mixed].valid == false",
            function()
                local player_names = {"ForceOne", "ForceTwo", "ForceThree"}
                for player_index, player_name in ipairs(player_names) do
                    game.players[player_index] = { player_index = player_index, name = player_name, valid = false}
                end
                for player_index in ipairs(player_names) do
                    assert.is_false(Game.get_player(player_index))
                end
            end
        )

        --Only describing these here as they will be the same for all
        describe('Area Metatable Protections',
            function()
                local Area = require 'stdlib/area/area'
                it('Should not allow adding new keys',
                    function()
                        assert.has_error(function() Area["fake"] = true end)
                    end
                )

                it('Should not allow setting a new metatable',
                    function()
                        assert.has_error(function() setmetatable(Area, {}) end)
                    end
                )

                it('Should not allow getting the metatable',
                    function()
                        assert.is_true(getmetatable(Area))
                    end
                )
            end
        )
    end
)
