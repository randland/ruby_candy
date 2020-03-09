# frozen_string_literal: true

require 'json'
require 'socket'

class RubyCandy::Client
  attr_reader :channel, :host, :port

  DEFAULT_CHANNEL = 0
  DEFAULT_HOST = 'localhost'
  DEFAULT_PORT = 7890
  DEFAULT_FIRMWARE_CONFIG = 0x00
  DEFAULT_COLOR_CORRECTION = {
    gamma: 2.5,
    whitepoint: [1.0, 1.0, 1.0],
    linearSlope: 1.0,
    linearCutoff: 0.0
  }.freeze

  DISABLE_DITHERING_BIT = 0x01
  DISABLE_INTERPOLATION_BIT = 0x02
  MANUAL_STATUS_BIT = 0x04
  STATUS_LED_BIT = 0x08

  def initialize(channel: DEFAULT_CHANNEL, host: DEFAULT_HOST, port: DEFAULT_PORT)
    @channel = channel
    @host = host
    @port = port

    @firmware_config  = DEFAULT_FIRMWARE_CONFIG
    @color_correction = DEFAULT_COLOR_CORRECTION.dup
  end

  def reset_firmware_config
    @firmware_config = DEFAULT_FIRMWARE_CONFIG
    send_firmware_config
  end

  def dithering=(val)
    case val
    when nil || 0 || false then disable_dithering
    else enable_dithering
    end
  end

  def disable_dithering
    set_firmware_bits(DISABLE_DITHERING_BIT)
    send_firmware_config
  end

  def enable_dithering
    unset_firmware_bits(DISABLE_DITHERING_BIT)
    send_firmware_config
  end

  def interpolation=(val)
    case val
    when nil || 0 || false then disable_interpolation
    else enable_interpolation
    end
  end

  def disable_interpolation
    set_firmware_bits(DISABLE_INTERPOLATION_BIT)
    send_firmware_config
  end

  def enable_interpolation
    unset_firmware_bits(DISABLE_INTERPOLATION_BIT)
    send_firmware_config
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
    send_firmware_config
  end

  def status_on
    set_firmware_bits(MANUAL_STATUS_BIT | STATUS_LED_BIT)
    send_firmware_config
  end

  def status_off
    set_firmware_bits(MANUAL_STATUS_BIT)
    unset_firmware_bits(STATUS_LED_BIT)
    send_firmware_config
  end

  def gamma=(val)
    @color_correction[:gamma] = val
    send_color_correction
  end

  def whitepoint=(rgb)
    @color_correction[:whitepoint] = rgb
    send_color_correction
  end

  def red_whitepoint=(val)
    @color_correction[:whitepoint][0] = val
    send_color_correction
  end

  def green_whitepoint=(val)
    @color_correction[:whitepoint][1] = val
    send_color_correction
  end

  def blue_whitepoint=(val)
    @color_correction[:whitepoint][2] = val
    send_color_correction
  end

  def linear_cutoff=(val)
    @color_correction[:linearCutoff] = val
    send_color_correction
  end

  def linear_slope=(val)
    @color_correction[:linearSlope] = val
    send_color_correction
  end

  private

  attr_reader :color_correction, :firmware_config, :socket

  def set_firmware_bits(bitmask)
    @firmware_config |= bitmask
  end

  def unset_firmware_bits(bitmask)
    @firmware_config &= ~bitmask
  end

  def send_firmware_config
    socket_send(firmware_config_packet)
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
      firmware_config
    ].pack('C*')
  end

  def send_color_correction
    socket_send(color_correction_packet)
  end

  def color_correction_packet
    data = color_correction_data
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

  def socket_send(packet)
    puts packet.inspect
    initialize_socket if socket.nil?

    socket.send(packet, 0)
  rescue StandardError => e
    puts e.inspect
    initialize_socket.send(packet, 0)
  end

  def initialize_socket
    @socket = TCPSocket.new(host, port)
    @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
    @socket
  end
end
