class WelcomeController < ApplicationController

  def index
    pets = pet_finder_request(25, current_user.preferred_location)
    @pets = create_pet_objects(pets)
  end

  def one
    pets = pet_finder_request(1, current_user.preferred_location)
    @pets = create_pet_objects(pets)
  end

  private

  KEY = ENV['PET_FINDER_KEY']
  OUTPUT = 'full'
  FORMAT = 'json'

  def pet_finder_request(this_many, zip_code = '11217')
    request_url = 'http://api.petfinder.com/pet.getRandom?key=' + KEY + '&location=' + zip_code + '&output=' + OUTPUT + '&format=' + FORMAT
    pets = []
    this_many.times do
      pet = HTTParty.get(request_url)
      pets << pet
    end
    pets
  end

  def get_options(options_obj)
    options = []
    if options_obj && options_obj.length > 1
      options_obj.each do |option|
        options << option['$t']
      end
    elsif options_obj && options_obj.length == 1
      options << options_obj['$t']
    end
    options
  end

  def create_pet_objects(pets)
    @pets = []
      pets.each do |potential_pet|
        pet = potential_pet["petfinder"]["pet"]

        #BASIC INFO
        petfinder_id =  pet["id"]["$t"]
        name = pet.has_key?("name") ? pet["name"]["$t"] : ''
        animal = pet.has_key?("animal") ? pet["animal"]['$t'] : ''
        description = pet.has_key?("description") ? pet["description"]["$t"] : ''
        age = pet.has_key?("age") ? pet["age"]["$t"] : ''
        size = pet.has_key?("size") ? pet["size"]["$t"] : ''
        gender = pet.has_key?("sex") ? pet["sex"]["$t"] : ''

        if pet.has_key?("breeds")
          if pet["breeds"].has_key?("breed")
            if pet["breeds"]["breed"].is_a?(Array)
              breed = pet["breeds"]["breed"][0]["$t"]
            else
              breed = pet["breeds"]["breed"]["$t"]
            end
          else
            breed=''
          end
        else
          breed = ''
        end

        #OPTIONS
        options = get_options(pet["options"]["option"])
          altered = options.include?('altered')? "true" : "false"
          shots = options.include?('hasShots')? "true" : "false"
          special_needs = options.select{|option| option != 'altered' && option != 'hasShots'}.join(', ')

        #LOCATION
        pet_contact = pet["contact"]
          contact_city = pet_contact.has_key?("city") ? pet_contact["city"]["$t"] : ''
          contact_zip = pet_contact.has_key?("zip") ? pet_contact["zip"]["$t"] : ''
          contact_state = pet_contact.has_key?("state") ? pet_contact["state"]["$t"] : ''
          contact_name = pet_contact.has_key?("name") ? pet_contact["name"]["$t"] : ''
          contact_email = pet_contact.has_key?("email") ? pet_contact["email"]["$t"] : ''
          contact_phone = pet_contact.has_key?("phone") ? pet_contact["phone"]["$t"] : ''

        #ALL PHOTOS
        photos = []
        if pet.has_key?("media") && pet["media"].has_key?("photos")
          pet["media"]["photos"]["photo"].each do |photo|
            if photo["@size"] == 'pn'
              photos << photo['$t']
            end
          end
        else
          photos << 'http://www.iconsdownload.net/icons/256/1588-paw-print-outline-icon.png'
        end

        potential_pet = Pet.new({
            petfinder_id: petfinder_id,
            name: name,
            animal: animal,
            description: description,
            age: age,
            size: size,
            gender: gender,
            breed: breed,
            altered: altered,
            shots: shots,
            special_needs: special_needs
          })

        photos.map! do |photo|
          Photo.new({url: photo, pet_id: potential_pet.id})
        end
        @pets << {pet: potential_pet, photos: photos}
      end

      @pets

  end

end
