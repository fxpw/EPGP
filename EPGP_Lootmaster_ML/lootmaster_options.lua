local mod = LootMaster:NewModule("EPGPLootmaster_Options")

--local LootMasterML = false

function mod:OnEnable()
  local options = {
    name = "EPGPLootMaster",
    type = "group",
    get = function(i) return LootMaster.db.profile[i[#i]] end,
    set = function(i, v) LootMaster.db.profile[i[#i]] = v end,
    args = {
        
        global = {
            order = 1,
            type = "group",
            hidden = function(info) return not LootMasterML end,
            name = "Основные настройки",
            
                args = {
                
                help = {
                    order = 0,
                    type = "description",
                    name = "EPGP это аддон для чесного и правильного распределения лута в игре. LootMaster помогает вам распределять лут вашему рейду и регестрировать это в системе ЕПГП.",
                },
                
                
                
                no_ml = {
                    order = 2,
                    type = "description",
                    hidden = function(info) return LootMasterML end,
                    name = "\r\n\r\n|cFFFF8080ПРЕДУПРЕЖДЕНИЕ: Большое количество настроек было спрятано, так как модуль МЛ не включен. Пожалуйста включите его со страницы выбора персонажей.|r",
                },
                
                config_group = {
                    order = 12,
                    type = "group",
                    guiInline = true,
                    hidden = function(info) return not LootMasterML end,
                    name = "Основные настройки",
                    args = {
                        
                        use_epgplootmaster = {
                            order = 2,
                            type = "select",
			                width = "double",
                            set = function(i, v) 
                                LootMaster.db.profile.use_epgplootmaster = v;
                                if v == 'enabled' then
                                    LootMasterML:EnableTracking();
                                elseif v == 'disabled' then
                                    LootMasterML:DisableTracking();
                                else
                                    LootMasterML.current_ml = nil;
                                    LootMasterML:GROUP_UPDATE();
                                end                               
                                
                            end,
                            name = "Использование EPGPLootmaster",
                            desc = "Контроль когда EPGPLootmaster включен или нет.",
                            values = {
                                ['enabled'] = 'Всегда использовать EPGPLootmaster для распределения лута, не спрашивая',
                                ['disabled'] = 'Никогда не использовать EPGPLootmaster для распределения лута',
                                ['ask'] = 'Спрашивать каждый раз, когда я становлюсь лутмастером'
                            },
                        },
                        
                        loot_timeout = {
                            order = 14,
                            type = "select",
			                width = "double",
                            name = "Время выбора лута",
                            desc = "Устанавливает количество время отведенного кандидату на выбор лута.",
                            values = {
                                [0] = 'Без времени',
                                [10] = '10 сек.',
                                [15] = '15 сек.',
                                [20] = '20 сек.',
                                [30] = '30 сек.',
                                [40] = '40 сек.',
                                [50] = '50 сек.',
                                [60] = '1 минута',
                                [90] = '1 мин 30 сек',
                                [150] = '2 мин 30 сек',
                                [300] = '5 мин',
                            },
                        }, 
                        
                        --[[defaultMainspecGP = {
                            order = 15.1,
                            type = "input",                    
                            name = "Default mainspec GP",
                            desc = "Fill this field to override the GP value for mainspec loot.",
                            width = 'normal',
                            validate = function(data, value) if value=='' then return true end; if not strmatch(value, '^%s*%d+%s-%%?%s*$') then return false else return true end end,
                            set = function(i, v) 
                                
                                if v == '' or not v then
                                    v = ''
                                    LootMaster.db.profile.defaultMainspecGPPercentage = false;
                                    LootMaster.db.profile.defaultMainspecGPValue = nil;
                                else
                                    value, perc = strmatch(v, '^%s*(%d+)%s-(%%?)%s*$')
                                    LootMaster.db.profile.defaultMainspecGPPercentage = (perc~=nil and perc~='');
                                    LootMaster.db.profile.defaultMainspecGPValue = tonumber(value);
                                end                               
                                LootMaster.db.profile.defaultMainspecGP = v;
                            end,
                            usage = "\r\nEmpty: use normal GP value"..
                                    "\r\n50%: use 50% of normal GP value"..
                                    "\r\n25: all items are worth 25 GP"
                        },
                        
                        defaultMinorUpgradeGP = {
                            order = 15.2,
                            type = "input",                    
                            name = "Default minor upgrade GP",
                            desc = "Fill this field to override the GP value for minor upgrade mainspec loot.",
                            width = 'normal',
                            validate = function(data, value) if value=='' then return true end; if not strmatch(value, '^%s*%d+%s-%%?%s*$') then return false else return true end end,
                            set = function(i, v) 
                                
                                if v == '' or not v then
                                    v = ''
                                    LootMaster.db.profile.defaultMinorUpgradeGPPercentage = false;
                                    LootMaster.db.profile.defaultMinorUpgradeGPValue = nil;
                                else
                                    value, perc = strmatch(v, '^%s*(%d+)%s-(%%?)%s*$')
                                    LootMaster.db.profile.defaultMinorUpgradeGPPercentage = (perc~=nil and perc~='');
                                    LootMaster.db.profile.defaultMinorUpgradeGPValue = tonumber(value);
                                end                               
                                LootMaster.db.profile.defaultMinorUpgradeGP = v;
                            end,
                            usage = "\r\nEmpty: use normal GP value"..
                                    "\r\n50%: use 50% of normal GP value"..
                                    "\r\n25: all items are worth 25 GP"
                        },
                        
                        defaultOffspecGP = {
                            order = 15.3,
                            type = "input",                    
                            name = "Default offspec GP",
                            desc = "Fill this field to override the GP value for offspec loot.",
                            width = 'normal',
                            validate = function(data, value) if value=='' then return true end; if not strmatch(value, '^%s*%d+%s-%%?%s*$') then return false else return true end end,
                            set = function(i, v) 
                                
                                if v == '' or not v then
                                    v = ''
                                    LootMaster.db.profile.defaultOffspecGPPercentage = false;
                                    LootMaster.db.profile.defaultOffspecGPValue = nil;
                                else
                                    value, perc = strmatch(v, '^%s*(%d+)%s-(%%?)%s*$')
                                    LootMaster.db.profile.defaultOffspecGPPercentage = (perc~=nil and perc~='');
                                    LootMaster.db.profile.defaultOffspecGPValue = tonumber(value);
                                end                               
                                LootMaster.db.profile.defaultOffspecGP = v;
                            end,
                            usage = "\r\nEmpty: use normal GP value"..
                                    "\r\n50%: use 50% of normal GP value"..
                                    "\r\n25: all items are worth 25 GP"
                        },
                        
                        defaultGreedGP = {
                            order = 15.4,
                            type = "input",                    
                            name = "Default greed GP",
                            desc = "Fill this field to override the GP value for greed loot.",
                            width = 'normal',
                            validate = function(data, value) if value=='' then return true end; if not strmatch(value, '^%s*%d+%s-%%?%s*$') then return false else return true end end,
                            set = function(i, v) 
                                
                                if v == '' or not v then
                                    v = ''
                                    LootMaster.db.profile.defaultGreedGPPercentage = false;
                                    LootMaster.db.profile.defaultGreedGPValue = nil;
                                else
                                    value, perc = strmatch(v, '^%s*(%d+)%s-(%%?)%s*$')
                                    LootMaster.db.profile.defaultGreedGPPercentage = (perc~=nil and perc~='');
                                    LootMaster.db.profile.defaultGreedGPValue = tonumber(value);
                                end                               
                                LootMaster.db.profile.defaultGreedGP = v;
                            end,
                            usage = "\r\nEmpty: use normal GP value"..
                                    "\r\n50%: use 50% of normal GP value"..
                                    "\r\n25: all items are worth 25 GP"
                        },]]
                        
                        ignoreResponseCorrections = {
                            type = "toggle",
                            order = 17,
                            width = 'full',
                            name = "Принимать только первого кандидата для каждой вещи.",
                            desc = "Нормально кандидаты могут отправлять несколько запросов на один лут что бы менять их выбор, если включена данная настройка, кандидаты не смогут изменить свой выбор",
                        },
                        
                        allowCandidateNotes = {
                            type = "toggle",
                            order = 18,
                            width = 'full',
                            name = "Позволить кандидатам добавлять заметки каждой вещи.",
                            desc = "Отметьте это если вы хотите что бы кандидаты отправляли вам заметки. Заметки будут показаны как иконка на вашем интерфейсе лута. Вы можете читать их наводя на икону.",
                        },
                        
                        filterEPGPLootmasterMessages = {
                            type = "toggle",
                            order = 19,
                            width = 'full',
                            name = "Фильтр оглашений в чат и шепотов.",
                            desc = "EPGPLootmaster имеет систему когда даже те кто не установил в рейде EPGPLootmaster могут принимать участие в розыгрыше вещи. Это можно зделать отослав сообщение в канал рейда. Включите эту настройку что бы фильтровать все сообщения с чата.",
                        },
                        
                        audioWarningOnSelection = {
                            type = "toggle",
                            order = 20,
                            width = 'full',
                            name = "Проигрывать аудио-предупреждение при всплывании окошка лута.",
                            desc = "Эта опция будет проигрывать звук когда появляется окошко распределения лута и требуется ваша реакция.",
                        },
                    }
                },
                
                buttons_group = {
                    order = 12.5,
                    type = "group",
                    guiInline = true,
                    hidden = function(info) return not LootMasterML end,
                    name = "Кнопки выбора",
                    args = {
                        
                        help = {
                            order = 0,
                            type = "description",
                            name = "Это позволит вам настроить кнопки выбора в меню пользователя ваших рейдеров.",
                        },
                        
                        buttonNum = {
                            type = "range",
                            width = 'full',
                            order = 1,
                            name = "Количество отображаемых кнопок:",
                            min = 1,
                            max = EPGPLM_MAX_BUTTONS,
                            step = 1,
                            desc = "Выбирете как много кнопок будет отображатся на ваших клиентах. Вы должны будете сконфигурировать 1 кнопку минимально и быть уверенным что кнопка пропуска всегда включена.",
                        },
                        
                        
                        button1 = {
                            type = "input",
                            width = 'full',
                            hidden = function(info) return LootMaster.db.profile.buttonNum < 1 end,
                            dialogControl = "EPGPLMButtonConfigWidget",
                            order = 1.1,
                            name = "кнопка1",
                            desc = "Настрой меня.",
                        },
                        
                        button2 = {
                            type = "input",
                            width = 'full',
                            hidden = function(info) return LootMaster.db.profile.buttonNum < 2 end,
                            dialogControl = "EPGPLMButtonConfigWidget",
                            order = 1.2,
                            name = "кнопка2",
                            desc = "Настрой меня.",
                        },
                        
                        button3 = {
                            type = "input",
                            width = 'full',
                            hidden = function(info) return LootMaster.db.profile.buttonNum < 3 end,
                            dialogControl = "EPGPLMButtonConfigWidget",
                            order = 1.3,
                            name = "кнопка3",
                            desc = "Настрой меня.",
                        },
                        
                        button4 = {
                            type = "input",
                            width = 'full',
                            hidden = function(info) return LootMaster.db.profile.buttonNum < 4 end,
                            dialogControl = "EPGPLMButtonConfigWidget",
                            order = 1.4,
                            name = "кнопка4",
                            desc = "Настрой меня.",
                        },
                        
                        button5 = {
                            type = "input",
                            width = 'full',
                            hidden = function(info) return LootMaster.db.profile.buttonNum < 5 end,
                            dialogControl = "EPGPLMButtonConfigWidget",
                            order = 1.5,
                            name = "кнопка5",
                            desc = "Настрой меня.",
                        },
                        
                        button6 = {
                            type = "input",
                            width = 'full',
                            hidden = function(info) return LootMaster.db.profile.buttonNum < 6 end,
                            dialogControl = "EPGPLMButtonConfigWidget",
                            order = 1.6,
                            name = "кнопка6",
                            desc = "Настрой меня.",
                        },
                        
                        button7 = {
                            type = "input",
                            width = 'full',
                            hidden = function(info) return LootMaster.db.profile.buttonNum < 7 end,
                            dialogControl = "EPGPLMButtonConfigWidget",
                            order = 1.7,
                            name = "кнопка7",
                            desc = "Настрой меня.",
                        },
                        
                        btnTestPopup = {
                            order = 3,
                            type = "execute",
                            width = 'full',
                            name = "Открыть тестовое окошко и окна мониторинга",
                            desc = "Открывает тестовое окошко и окошко мониторинга, так что бы вы виделы как это будет выглядеть на ваших клиентах. Как только вы закончили тестировать, нажмите кнопку распределения лута что бы закрыть окно мониторинга.",
                            func = function()
                                local lootLink
                                for i=1, 20 do
                                  lootLink = GetInventoryItemLink("player", i)
                                  if lootLink then break end
                                end
                                if not lootLink then return end
                                
                                ml = LootMasterML        
                                local loot = ml:GetLoot(lootLink)
                                local added = false
                                if not loot then
                                    local lootID = ml:AddLoot(lootLink, true)
                                    loot = ml:GetLoot(lootID)
                                    loot.announced = false
                                    loot.manual = true
                                    added = true
                                end
                                if not loot then return self:Print('Немогу зарегестрировать лут.') end          
                                ml:AddCandidate(loot.id, UnitName('player'))
                                ml:AnnounceLoot(loot.id)
                                for i=1, LootMaster.db.profile.buttonNum do
                                  ml:AddCandidate(loot.id, 'Button ' .. i)
                                  ml:SetCandidateResponse(loot.id, 'Button ' .. i, LootMaster.RESPONSE['button'..i], true)
                                end
                                ml:ReloadMLTableForLoot(loot.link)
                            end
                        },
                    },
                },
                
                auto_hiding_group = {
                    order = 13,
                    type = "group",
                    guiInline = true,
                    hidden = function(info) return not LootMasterML end,
                    name = "Авто скрытие",
                    args = {
                        
                        help = {
                            order = 0,
                            type = "description",
                            name = "Это позволяет вам контролировать возможности автоматического скрытия EPGPLootmaster.",
                        },
                                
                        hideOnSelection = {
                            type = "toggle",
                            order = 16,
                            width = 'full',
                            name = "Прятать окно мониторинга когда открывается окно выбора лута.",
                            desc = "Выбирите это что бы автоматом прятать Master Looter/Окно Мониторинга когда вам нужно выбрать приоритет на лут.",
                        },
                        
                        hideMLOnCombat = {
                            type = "toggle",
                            order = 17,
                            width = 'full',
                            name = "Спрятать окно мониторинга при входе в бой.",
                            desc = "Автоматом восстановится при выходе из боя.",
                        },
                        
                        hideSelectionOnCombat = {
                            type = "toggle",
                            order = 18,
                            width = 'full',
                            name = "Спрятать окошко выбора лута при входе в бой.",
                            desc = "Автоматом появится при выходе из боя.",
                        },
                    },
                },
                
                auto_announce_group = {
                    order = 14,
                    type = "group",
                    guiInline = true,
                    hidden = function(info) return not LootMasterML end,
                    name = "Авто Оглашение",
                    args = {
                        
                        help = {
                            order = 0,
                            type = "description",
                            name = "EPGP Lootmaster Авто Оглашение позволяет вам авто анонсировать специфический лут рейду.",
                        },
                                
                        auto_announce_threshold = {
                            order = 13,
                            type = "select",
                            width = 'full',
                            hidden = function(info) return not LootMasterML end,
                            name = "Авто оглашение Треша",
                            desc = "Автоматом оглашает треш, любой лут который эквивалентный или лучше по качество будет авто анонсирован рейду.",
                            values = {
                                [0] = 'Never auto announce',
                                [2] = ITEM_QUALITY2_DESC,
                                [3] = ITEM_QUALITY3_DESC,
                                [4] = ITEM_QUALITY4_DESC,
                                [5] = ITEM_QUALITY5_DESC,
                            },
                        },
                    },
                },
                
                
                AutoLootGroup = {
            
                            type = "group",
                            order = 16,
                            guiInline = true,
                            name = "Авто Лут",
                            desc = "Авто Лут вещей",
                            hidden = function(info) return not LootMasterML end,
                            args = {
                                
                                help = {
                                    order = 0,
                                    type = "description",
                                    name = "EPGP Lootmaster авто лут позволяет вам отсылать различные ЛпО(Личное при одевании) и ЛпИ(личное при использовании) вещи к уже определенному кандидату без вопросов.",
                                },
                                
                                AutoLootThreshold = {
                                    order = 1,
                                    type = "select",
                                    width = 'full',
                                    hidden = function(info) return not LootMasterML end,
                                    name = "Автолут треша(ЛпО и ЛпИ вещи только)",
                                    desc = "Ставит автоматическое распределение треша, любая ЛпО и ЛпИ вещь меньше определенного уровня качества автоматом отправится кандидату ниже.",
                                    values = {
                                        [0] = 'Never auto loot',
                                        [2] = ITEM_QUALITY2_DESC,
                                        [3] = ITEM_QUALITY3_DESC,
                                        [4] = ITEM_QUALITY4_DESC,
                                        [5] = ITEM_QUALITY5_DESC,
                                    },
                                },
                                
                                AutoLooter = {
                                    type = "select",
                                    style = 'dropdown',
                                    order = 2,
                                    width = 'full',
                                    name = "Имя стандартного кандидата:",
                                    desc = "Пожалуйста введите имя стандартного кандидата для получения вещей Личное При Одевании(ЛпО) и Личное при Использовании(ЛпИ).",
                                    disabled = function(info) return (LootMaster.db.profile.AutoLootThreshold or 0)==0 end,
                                    values = function()
                                        local names = {}
                                        local name;
                                        local num = GetNumRaidMembers()
                                        if num>0 then
                                            -- we're in raid
                                            for i=1, num do 
                                                name = GetRaidRosterInfo(i)
                                                names[name] = name
                                            end
                                        else
                                            num = GetNumPartyMembers()
                                            if num>0 then
                                                -- we're in party
                                                for i=1, num do 
                                                    names[UnitName('party'..i)] = UnitName('party'..i)
                                                end
                                                names[UnitName('player')] = UnitName('player')
                                            else
                                                -- Just show everyone in guild.
                                                local num = GetNumGuildMembers(true);
                                                for i=1, num do repeat
                                                    name = GetGuildRosterInfo(i)
                                                    names[name] = name
                                                until true end     
                                            end                                   
                                        end
                                        sort(names)
                                        return names;
                                    end
                                },
                            }
                },
            
        
        
                MonitorGroup = {
                            type = "group",
                            order = 17,
                            guiInline = true,
                            hidden = function(info) return not LootMasterML end,
                            name = "Мониторинг",
                            desc = "Отправлять и получать сообщения от мастерЛутера и видеть что выбрали другие члены рейда.",
                            args = {
                                
                                help = {
                                    order = 0,
                                    type = "description",
                                    name = "EPGP Lootmaster Монитор aпозволяет вам отправлять сообещния другим пользователям в вашем рейде. Это покажет такой же интерфейс как и ML, позволяя им помочь с распределением лута.",
                                },
                
                                monitor = {
                                    type = "toggle",
                                    set = function(i, v)
                                        LootMaster.db.profile[i[#i]] = v;
                                        if LootMasterML and LootMasterML.UpdateUI then
                                            LootMasterML.UpdateUI( LootMasterML );
                                        end
                                    end,
                                    order = 1,
                                    width = 'full',
                                    name = "Слушать входящие обновления",
                                    desc = "Отметьте это если вы хотите отображать входящие обновления. Эта функция позволит вам видеть интерфейс МастерЛутера что бы вы могли помочь ему с распределением лута.",
                                    disabled = false,
                                },
                                
                                monitorIncomingThreshold = {
                                    order = 2,
                                    width = 'normal',
                                    type = "select",
                                    name = "Получать только для эквивалентной или лучшей вещи",
                                    desc = "Слушать только сообщения с эквивалентными или лучшими вещами. (Также относится к свиткам)",
                                    disabled = function(info) return not LootMaster.db.profile.monitor end,
                                    values = {
                                        [2] = ITEM_QUALITY2_DESC,
                                        [3] = ITEM_QUALITY3_DESC,
                                        [4] = ITEM_QUALITY4_DESC,
                                        [5] = ITEM_QUALITY5_DESC,
                                    },
                                },
                                
                                monitorSend = {
                                    type = "toggle",
                                    order = 3.1,
                                    width = 'full',
                                    name = "ВСе видят ваше окошко",
                                    desc = "Отмечая эту опцию, вы позволяете всем игрокам видеть ваше окошко распределения лута.",
                                    disabled = false,
                                },
                                
                                monitorSendAssistantOnly = {
                                    type = "toggle",
                                    order = 3.2,
                                    disabled = function(info) return not LootMaster.db.profile.monitorSend end,
                                    width = 'full',
                                    name = "Отправлять только повышеным игрокам",
                                    desc = "Показывает окошко мониторинга только игрокам на которых лежит ответственость распределения лута.",
                                },
                                
                                hideResponses = {
                                    type = "toggle",
                                    disabled = function(info) return not LootMaster.db.profile.monitorSend end,
                                    order = 3.3,
                                    width = 'full',
                                    name = "Скрытый выбор",
                                    desc = "Это широко-рейдная опция. Прчет ответы всех игроков, что бы другие игроки не делали выбор по результатам выбора остальных.",
                                },
                                
                                monitorThreshold = {
                                    order = 4,
                                    width = 'normal',
                                    type = "select",
                                    name = "Отправлять только для эквивалентной или вещи получше",
                                    desc = "Отправлять сообщения мониторинга рейду для вещей которые совпадают с этим лутом или выше. (Свитки также входят в эту опцию.)",
                                    disabled = function(info) return not LootMaster.db.profile.monitorSend end,
                                    values = {
                                        [2] = ITEM_QUALITY2_DESC,
                                        [3] = ITEM_QUALITY3_DESC,
                                        [4] = ITEM_QUALITY4_DESC,
                                        [5] = ITEM_QUALITY5_DESC,
                                    },
                                },
                                
                                hint = {
                                    order = 5,
                                    width = 'normal',
                                    hidden = function(info) return not LootMaster.db.profile.monitorSend end,
                                    type = "description",
                                    name = "  Только ЛпО и ЛпИ вещи будут фильтрованы. Вещи ЛпВ будут всегда отправлятся на окно монитора.",
                                },
                            }
                },
                
                ExtraFunctionGroup = {
                            type = "group",
                            order = 18,
                            guiInline = true,
                            hidden = function(info) return not LootMasterML end,
                            name = "Дополнительные функции",
                            args = {
                                
                                help = {
                                    order = 0,
                                    type = "description",
                                    name = "Некоторые дополнительные функции которые идут дополнительно.",
                                },
                                btnVersionCheck = {
                                  order = 1000,
                                  type = "execute",
                                  name = "Проверка версии",
                                  desc = "Открывает проверщика версии.",
                                  func = function()
                                           LootMaster:ShowVersionCheckFrame()
                                         end
                                },
                                
                                btnRaidInfoCheck = {
                                  order = 2000,
                                  type = "execute",
                                  name = "Проверка Инфо Рейда",
                                  desc = "Проверка, какие игроки сохранены в подземелье.",
                                  func = function()
                                           LootMasterML:ShowRaidInfoLookup()
                                         end
                                }
                                
                                
                                
                
                                
                            }
                }
            },
        },
    },
  }

  local config = LibStub("AceConfig-3.0")
  local dialog = LibStub("AceConfigDialog-3.0")

  config:RegisterOptionsTable("EPGPLootMaster-Bliz", options)
  dialog:AddToBlizOptions("EPGPLootMaster-Bliz", "EPGPLootMaster", nil, 'global')
  --dialog:AddToBlizOptions("EPGPLootMaster-Bliz", "Monitor", "EPGPLootMaster", 'MonitorGroup')
  
end