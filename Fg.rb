def upload
    require "csv"

    guardian.ensure_can_admin_tags!

    file = params[:file] || params[:files].first

    hijack do
      begin
        Tag.transaction do
          CSV.foreach(file.tempfile) do |row|
            if row.length > 2
              raise Discourse::InvalidParameters.new(I18n.t("tags.upload_row_too_long"))
            end

            tag_name = DiscourseTagging.clean_tag(row[0])
            tag_group_name = row[1] || nil

            tag = Tag.find_by_name(tag_name) || Tag.create!(name: tag_name)

            if tag_group_name
              tag_group =
                TagGroup.find_by(name: tag_group_name) || TagGroup.create!(name: tag_group_name)
              tag.tag_groups << tag_group if tag.tag_groups.exclude?(tag_group)
            end
          end
        end
        render json: success_json
      rescue Discourse::InvalidParameters => e
        render json: failed_json.merge(errors: [e.message]), status: 422
      end
    end
  end

  def list_unused
    guardian.ensure_can_admin_tags!
    render json: { tags: Tag.unused.pluck(:name) }
  end
