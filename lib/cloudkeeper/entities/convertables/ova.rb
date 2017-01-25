module Cloudkeeper
  module Entities
    module Convertables
      module Ova
        CONVERT_OUTPUT_FORMATS = [:raw, :qcow2].freeze

        def self.convert_output_formats
          CONVERT_OUTPUT_FORMATS
        end

        def self.extended(base)
          raise Cloudkeeper::Errors::Convertables::ConvertabilityError, "#{base.inspect} cannot become OVA convertable" \
            unless base.class.included_modules.include?(Cloudkeeper::Entities::Convertables::Convertable)

          super
        end

        def to_vmdk
          image_file(extract_disk, :vmdk)
        end

        def to_ova
          self
        end

        private

        def convert(output_format)
          logger.debug "Converting file #{file.inspect} from #{format.inspect} to #{output_format.inspect}"
          vmdk_image = to_vmdk
          final_image = vmdk_image.send("to_#{output_format}".to_sym)
          File.delete vmdk_image.file

          final_image
        end

        def extract_disk
          archived_disk = disk_file
          disk_directory = File.dirname(file)
          Cloudkeeper::CommandExecutioner.execute('tar', '-x', '-f', file, '-C', disk_directory, archived_disk)
          File.join(disk_directory, archived_disk)
        end

        def archive_files
          Cloudkeeper::CommandExecutioner.list_archive file
        end

        def disk_file
          archive_files.each { |file| return file if Cloudkeeper::Entities::ImageFormats::Ova::VMDK_REGEX =~ file }
        end
      end
    end
  end
end
