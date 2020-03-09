# frozen_string_literal: true

module RubyCandy
  class Client
    module PixelsAPI
      BadColorCount = Class.new(ArgumentError)
      VAR_NAME = '@pixels'

      def reset_pixels(length: 0, default_color: [0, 0, 0], send: true)
        instance_variable_set(VAR_NAME, Pixels.new(length: length, default_color: default_color))
        send_pixels if send
      end

      def pixels=(rgb_array)
        instance_variable_get(VAR_NAME).public_send(:pixels=, rgb_array.flatten)
        send_pixels
      end

      def []=(idx, rgb_array)
        instance_variable_get(VAR_NAME).public_send(:[]=, idx, rgb_array)
      end

      def send_pixels
        if defined?(:socket_send)
          socket_send(pixels_packet)
        else
          puts pixel_packet.inspect
        end
      end

      private

      def pixel_bytes
        instance_variable_get(VAR_NAME).pixel_colors.pack('C*')
      end

      def pixels_packet
        pixels_header + pixel_bytes
      end

      def pixels_header
        [
          channel,
          0x00,
          pixel_bytes.length
        ].pack('CCS>')
      end

      class Pixels
        attr_reader :default_color, :pixel_colors

        def initialize(length: 0, default_color: [0, 0, 0])
          @default_color = default_color
          @pixel_colors = Array.new(length) { default_color }.flatten
        end

        def pixel_count
          pixel_colors.count / 3
        end

        def pixels=(rgb_array)
          new_colors = rgb_array.dup.flatten
          raise BadColorCount if new_colors.count % 3 != 0

          @pixel_colors = rgb_array
        end

        def []=(index, rgb_array)
          raise BadColorCount if rgb_array.count != 3

          if pixel_count < index
            missing_pixels = index - pixel_count
            missing_pixels.times { @pixel_colors += default_color }
          end

          pixel_colors[index * 3] = rgb_array[0]
          pixel_colors[index * 3 + 1] = rgb_array[1]
          pixel_colors[index * 3 + 2] = rgb_array[2]
        end
      end
    end
  end
end
