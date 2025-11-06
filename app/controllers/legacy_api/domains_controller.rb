# frozen_string_literal: true

module LegacyAPI
  class DomainsController < BaseController

    # GET/POST /api/v1/domains/list
    # Returns a list of all domains for the authenticated server
    def list
      domains = @current_credential.server.domains.map do |domain|
        domain_to_hash(domain)
      end

      render_success domains: domains
    end

    # GET/POST /api/v1/domains/info
    # Returns information about a specific domain
    # Required params: name (domain name)
    def info
      domain_name = api_params["name"]

      if domain_name.blank?
        render_parameter_error "Domain name is required"
        return
      end

      domain = @current_credential.server.domains.find_by(name: domain_name)

      if domain.nil?
        render_error "DomainNotFound", message: "Domain '#{domain_name}' not found"
        return
      end

      render_success domain: domain_to_hash(domain)
    end

    # POST /api/v1/domains/create
    # Creates a new domain
    # Required params: name (domain name)
    # Optional params: verification_method (DNS or Email, defaults to DNS)
    def create
      domain_name = api_params["name"]

      if domain_name.blank?
        render_parameter_error "Domain name is required"
        return
      end

      # Check if domain already exists
      existing = @current_credential.server.domains.find_by(name: domain_name)
      if existing
        render_error "DomainAlreadyExists",
                     message: "Domain '#{domain_name}' already exists",
                     domain: domain_to_hash(existing)
        return
      end

      verification_method = api_params["verification_method"] || "DNS"
      unless Domain::VERIFICATION_METHODS.include?(verification_method)
        render_parameter_error "Invalid verification_method. Must be DNS or Email"
        return
      end

      domain = @current_credential.server.domains.build(
        name: domain_name,
        verification_method: verification_method
      )

      if domain.save
        render_success domain: domain_to_hash(domain)
      else
        render_error "ValidationError",
                     message: "Failed to create domain",
                     errors: domain.errors.full_messages
      end
    end

    # POST /api/v1/domains/delete
    # Deletes a domain
    # Required params: name (domain name)
    def delete
      domain_name = api_params["name"]

      if domain_name.blank?
        render_parameter_error "Domain name is required"
        return
      end

      domain = @current_credential.server.domains.find_by(name: domain_name)

      if domain.nil?
        render_error "DomainNotFound", message: "Domain '#{domain_name}' not found"
        return
      end

      if domain.destroy
        render_success message: "Domain deleted successfully"
      else
        render_error "DeleteFailed",
                     message: "Failed to delete domain",
                     errors: domain.errors.full_messages
      end
    end

    private

    def domain_to_hash(domain)
      {
        id: domain.id,
        uuid: domain.uuid,
        name: domain.name,
        verified: domain.verified?,
        verified_at: domain.verified_at&.iso8601,
        verification_method: domain.verification_method,
        verification_token: domain.verification_token,
        dns_checked_at: domain.dns_checked_at&.iso8601,
        spf_status: domain.spf_status,
        spf_error: domain.spf_error,
        dkim_status: domain.dkim_status,
        dkim_error: domain.dkim_error,
        mx_status: domain.mx_status,
        mx_error: domain.mx_error,
        return_path_status: domain.return_path_status,
        return_path_error: domain.return_path_error,
        outgoing: domain.outgoing,
        incoming: domain.incoming,
        use_for_any: domain.use_for_any,
        dns_records: {
          spf: {
            type: "TXT",
            name: "@",
            value: domain.spf_record
          },
          dkim: {
            type: "TXT",
            name: domain.dkim_record_name,
            value: domain.dkim_record
          },
          dkim_identifier: domain.dkim_identifier,
          return_path: {
            type: "CNAME",
            name: domain.return_path_domain,
            value: Postal::Config.dns.return_path
          },
          verification: domain.verification_method == "DNS" ? {
            type: "TXT",
            name: "@",
            value: domain.dns_verification_string
          } : nil
        },
        created_at: domain.created_at.iso8601,
        updated_at: domain.updated_at.iso8601
      }
    end

  end
end
