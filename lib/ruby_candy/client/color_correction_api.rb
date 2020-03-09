# frozen_string_literal: true

module RubyCandy
  class Client
    module ColorCorrectionAPI
      API_METHODS = %i[
        gamma=
        linear_cutoff=
        linear_slope=
        whitepoint=
      ].freeze
      VAR_NAME = '@color_correction'

      def reset_color_correction(send: true)
        instance_variable_set(VAR_NAME, ColorCorrection.new)
        send_color_correction if send
      end

      def send_color_correction
        if defined?(:socket_send)
          socket_send(color_correction_packet)
        else
          puts color_correction_packet.inspect
        end
      end

      API_METHODS.each do |delegated_method|
        define_method(delegated_method) do |*args|
          instance_variable_get(VAR_NAME).public_send(delegated_method, *args)
          send_color_correction
        end
      end

      private

      def color_correction_bytes
        instance_variable_get(VAR_NAME).config_hash.to_json.bytes
      end

      def color_correction_packet
        data = color_correction_bytes
        data_length = data.count + 4
        header = color_correction_header(data_length)
        (header + data).pack('C*')
      end

      def color_correction_data
        @color_correction.to_json.bytes
      end

      def color_correction_header(data_length)
        [
          0x00,                 # Channel (reserved)
          0xFF,                 # Command (System Exclusive)
          (data_length >> 8),   # Length high byte
          (data_length & 0xFF), # Length low byte
          0x00,                 # System ID high byte
          0x01,                 # System ID low byte
          0x00,                 # Command ID high byte
          0x01
        ]
      end

      class ColorCorrection
        DEFAULT_HASH = {
          gamma: 2.5,
          linearCutoff: 0.0,
          linearSlope: 1.0,
          whitepoint: [1.0, 1.0, 1.0]
        }.freeze

        attr_reader :config_hash

        def initialize(config_hash: DEFAULT_HASH)
          @config_hash = config_hash
        end

        def gamma=(val)
          config_hash[:gamma] = val
        end

        def linear_cutoff=(val)
          config_hash[:linearCutoff] = val
        end

        def linear_slope=(val)
          config_hash[:linearSlope] = val
        end

        def whitepoint=(val)
          config_hash[:whitepoint] = val
        end
      end
    end
  end
end
