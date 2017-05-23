module Cloudkeeper
  module Entities
    module Convertables
      module Ova
        CONVERT_OUTPUT_FORMATS = %i[raw qcow2 vdi ova].freeze

        def self.extended(base)
          raise Cloudkeeper::Errors::Convertables::ConvertabilityError, "#{base.inspect} cannot become OVA convertable" \
            unless base.class.included_modules.include?(Cloudkeeper::Entities::Convertables::Convertable)

          super
        end

        def convert_output_formats
          CONVERT_OUTPUT_FORMATS
        end

        def to_vmdk
          logger.debug "Converting file #{file.inspect} from #{format.inspect} to vmdk"
          image_file(extract_disk, :vmdk)
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
          extracted_file = File.join(disk_directory, archived_disk)
          Cloudkeeper::CommandExecutioner.execute('tar', '-x', '-f', file, '-C', disk_directory, archived_disk)
          extracted_file
        rescue Cloudkeeper::Errors::CommandExecutionError => ex
          delete_if_exists extracted_file
          raise ex
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
