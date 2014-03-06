# Puppet Library
# Copyright (C) 2014 drrb
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'logger'

module PuppetLibrary::Util
    module Logging
        def log_io
            @log_io ||= StringIO.new
        end

        def logger
            destination = ENV["TESTING"] ? log_io : STDERR
            @logger ||= Logger.new(destination).tap do |logger|
                logger.progname = self.class.name
                logger.level = Logger::DEBUG
            end
        end

        def debug(message)
            logger.debug message
        end

        def info(message)
            logger.info message
        end

        def warn(message)
            logger.warn message
        end

        #def error(message)
        #    logger.error message
        #end
    end
end
