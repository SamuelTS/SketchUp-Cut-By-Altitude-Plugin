# Cut By Altitude extension for SketchUp 2017 or newer.
# Copyright: © 2019 Samuel Tallet <samuel.tallet arobase gmail.com>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3.0 of the License, or
# (at your option) any later version.
# 
# If you release a modified version of this program TO THE PUBLIC,
# the GPL requires you to MAKE THE MODIFIED SOURCE CODE AVAILABLE
# to the program's users, UNDER THE GPL.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
# 
# Get a copy of the GPL here: https://www.gnu.org/licenses/gpl.html

raise 'The CBA plugin requires at least Ruby 2.2.0 or SketchUp 2017.'\
  unless RUBY_VERSION.to_f >= 2.2 # SketchUp 2017 includes Ruby 2.2.4.

require 'sketchup'

# CBA plugin namespace.
module CBA

  # Cutter.
  class Cut

    # Cuts by altitude a group, possibly many times.
    #
    # @param [Sketchup::Group] entity Entity to cut.
    # @raise [ArgumentError]
    #
    # @return [nil]
    def self.do_many_times(entity)

      raise ArgumentError, 'Entity argument must be a Sketchup::Group.'\
        unless entity.is_a?(Sketchup::Group)

      parameters = UI.inputbox(

        [
          TRANSLATE['Altitude in meters'] + ' ',
          TRANSLATE['Cut whole group?']
        ], # Prompts

        [
          1,
          TRANSLATE['Yes']
        ], # Defaults

        [
          '', TRANSLATE['Yes'] + '|' + TRANSLATE['No'] 
        ], # List

        TRANSLATE[NAME] # Title

      )

      # Escapes if user cancelled operation.
      return if parameters == false

      altitude = parameters[0].to_i
      base_altitude = altitude

      cut_whole_group = (parameters[1] == TRANSLATE['Yes'])

      entity_bounds = entity.bounds
      entity_height = (entity_bounds.max.z - entity_bounds.min.z).to_l.to_m.to_i

      many = (entity_height / altitude) - 1

      if cut_whole_group

        many.times do

          self.new(entity, altitude)

          altitude = altitude + base_altitude

        end

      else

        self.new(entity, altitude)

      end

    end

    # Initializes cut by altitude...
    #
    # @param [Sketchup::Group] entity Entity to cut.
    # @param [Integer] altitude Altitude in meters.
    # @raise [ArgumentError]
    def initialize(entity, altitude)

      raise ArgumentError, 'Entity argument must be a Sketchup::Group.'\
        unless entity.is_a?(Sketchup::Group)

      raise ArgumentError, 'Altitude argument must be an Integer.'\
        unless altitude.is_a?(Integer)

      model = Sketchup.active_model

      begin

        model.start_operation(
          TRANSLATE[NAME],
          true # disable_ui
        )

        Sketchup.status_text\
          = TRANSLATE['Cut By Altitude is running... Please wait.']

        entities = model.active_entities

        entity_bounds = entity.bounds

        face = entities.add_face(
          entity_bounds.corner(0),
          entity_bounds.corner(2),
          entity_bounds.corner(3),
          entity_bounds.corner(1)
        )

        face.reverse!

        face.pushpull(
          altitude.m,
          false # copy
        )

        group = entities.add_group(face.all_connected)

        entities.intersect_with(
          true, # recurse
          Geom::Transformation.new,
          entity,
          entity.transformation,
          true, # hidden
          group
        )

        group.erase!

        model.commit_operation

        Sketchup.status_text = nil
          
      rescue StandardError => exception

        model.abort_operation

        Sketchup.status_text = nil

        puts 'Error: ' + exception.message
        
      end

    end

  end

end
