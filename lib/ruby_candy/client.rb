# frozen_string_literal: true

require 'ruby_candy/client/color_correction_api'
require 'ruby_candy/client/firmware_config_api'

require 'socket'

module RubyCandy
  class Client
    include FirmwareConfigAPI
    include ColorCorrectionAPI
    attr_reader :channel, :host, :port

    DEFAULT_CHANNEL = 0
    DEFAULT_HOST = 'localhost'
    DEFAULT_PORT = 7890

    def initialize(channel: DEFAULT_CHANNEL, host: DEFAULT_HOST, port: DEFAULT_PORT)
      @channel = channel
      @host = host
      @port = port

      reset_firmware_config(send: false)
      reset_color_correction(send: false)
    end

    private

    attr_reader :socket

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
end
