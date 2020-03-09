# frozen_string_literal: true

require 'json'

module RubyCandy
  class Client
    module FirmwareConfigAPI
      API_METHODS = %i[
        auto_status
        dithering=
        interpolation=
        status=
      ].freeze
      VAR_NAME = '@firmware_config'

      API_METHODS.each do |delegated_method|
        define_method(delegated_method) do |*args|
          instance_variable_get(VAR_NAME).public_send(delegated_method, *args)
          send_firmware_config
        end
      end

      def reset_firmware_config(send: true)
        instance_variable_set(VAR_NAME, FirmwareConfig.new)
        send_firmware_config if send
      end

      def send_firmware_config
        if defined?(:socket_send)
          socket_send(firmware_config_packet)
        else
          puts firmware_config_packet.inspect
        end
      end

      private

      def firmware_config_byte
        instance_variable_get(VAR_NAME).config_byte
      end

      def firmware_config_packet
        [
          0x00, # Channel (reserved)
          0xFF, # Command (System Exclusive)
          0x00, # Length high byte
          0x05, # Length low byte
          0x00, # System ID high byte
          0x01, # System ID low byte
          0x00, # Command ID high byte
          0x02, # Command ID low byte
          firmware_config_byte
        ].pack('C*')
      end

      class FirmwareConfig
        DEFAULT_FIRMWARE_CONFIG = 0x00
        DISABLE_DITHERING_BIT = 0x01
        DISABLE_INTERPOLATION_BIT = 0x02
        MANUAL_STATUS_BIT = 0x04
        STATUS_LED_BIT = 0x08

        attr_reader :config_byte

        def initialize(config_byte: DEFAULT_FIRMWARE_CONFIG)
          @config_byte = config_byte
        end

        def set_firmware_bits(bitmask)
          @config_byte |= bitmask
        end

        def unset_firmware_bits(bitmask)
          @config_byte &= ~bitmask
        end

        def dithering=(val)
          case val
          when nil || 0 || false then disable_dithering
          else enable_dithering
          end
        end

        def disable_dithering
          set_firmware_bits(DISABLE_DITHERING_BIT)
        end

        def enable_dithering
          unset_firmware_bits(DISABLE_DITHERING_BIT)
        end

        def interpolation=(val)
          case val
          when nil || 0 || false then disable_interpolation
          else enable_interpolation
          end
        end

        def disable_interpolation
          set_firmware_bits(DISABLE_INTERPOLATION_BIT)
        end

        def enable_interpolation
          unset_firmware_bits(DISABLE_INTERPOLATION_BIT)
        end

        def status=(val)
          case val
          when nil then auto_status
          when 0 || false then status_off
          else status_on
          end
        end

        def auto_status
          unset_firmware_bits(MANUAL_STATUS_BIT | STATUS_LED_BIT)
        end

        def status_on
          set_firmware_bits(MANUAL_STATUS_BIT | STATUS_LED_BIT)
        end

        def status_off
          set_firmware_bits(MANUAL_STATUS_BIT)
          unset_firmware_bits(STATUS_LED_BIT)
        end
      end
    end
  end
end
