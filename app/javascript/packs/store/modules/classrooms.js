import axios from 'axios'

import mutations from '../mutations.js'
import getters from '../getters.js'
import actions from '../actions.js'

const classrooms = {
  namespaced: true,
  state: {
    selected: null,
    options: [],
    required: false,
    isLoading: true,
    fetchAssociation: 'teachers/fetch'
  },
  mutations,
  getters,
  actions: {
    ...actions,
    preLoad({ dispatch, commit, getters }) {
      commit('setOptions', window.state.available_classrooms.concat({}))
      commit('setSelected', getters.getById(window.state.current_classroom_id))
      commit('setIsLoading', false)
    },
    fetch({ dispatch, state, commit, rootState, rootGetters }) {
      commit('setIsLoading', true)
      commit('setSelected', null)
      commit('setOptions', [])
      commit('teachers/setSelected', null, { root: true })
      commit('teachers/setOptions', [], { root: true })
      commit('disciplines/setOptions', [], { root: true })
      commit('disciplines/setSelected', null, { root: true })

      const filters = {
        by_unity: rootState.unities.selected.id,
        by_year: rootState.school_years.selected.id
      }

      if(rootGetters['roles/is']('teacher')) {
        filters['by_teacher_id'] = window.state.teacher_id
      }

      const route = Routes.classrooms_pt_br_path({
        filter: filters,
        format: 'json'
      })

      axios
        .get(route)
        .then(response => {
          commit('setOptions', response.data)

          if(response.data.length === 1) {
            dispatch('setSelected', response.data[0])
          }
        })
        .finally(() => commit('setIsLoading', false))
    }
  }
}

export default classrooms
